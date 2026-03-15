local CrewBalance = {}

function CrewBalance.balanceCrewForForemanShips(
    factionIndex, 
    targetEntityId, 
    allowOverdrawPilots, 
    depth,
    onServer,
    foreman,
    fms
)
    depth = depth or 0
    if not onServer() then return end
    
    local sector = Sector()
    local shipsInSector = {sector:getEntitiesByType(EntityType.Ship)}
    local eligible = {}
    local requireForeman = (targetEntityId == nil)
    
    for _, e in pairs(shipsInSector) do
        if valid(e) and e.factionIndex == factionIndex then
            local include = true
            if requireForeman then
                include = false
                local sys = ShipSystem(e.id)
                if sys then
                    for upg, perm in pairs(sys:getUpgrades()) do
                        if upg and upg.script == "data/scripts/systems/foremansystem.lua" then
                            include = true
                            break
                        end
                    end
                end
            end
            if include then table.insert(eligible, e) end
        end
    end
    if #eligible < 2 then
        if depth == 0 then
            local msg = requireForeman and "No other Foreman ships in sector to balance crew." or "No other ships in sector to move crew from."
            sector:broadcastChatMessage("Foreman", ChatMessageType.Information, msg)
        end
        return 0
    end
    local Profession = CrewProfessionType
    local professions = {
        Profession.Pilot, Profession.Engine, Profession.Repair, Profession.Gunner,
        Profession.Miner, Profession.Security, Profession.Attacker, Profession.None
    }
    local safetyReserveAllrounders = 0
    local shipInfo = {}
    local targetIndexStr = nil
    local function toWFMap(userdataMap)
        local out = {}
        for profession, workforce in pairs(userdataMap or {}) do
            out[profession.value] = workforce
        end
        return out
    end
	local function countTotalFightersIncludingDeployed(entityId)
		local hangar = Hangar(entityId)
		if not hangar then return 0 end
		local total = hangar.numFighters or 0
		local controller = FighterController(entityId)
		if controller then
			local squads = {hangar:getSquads()}
			for _, idx in pairs(squads) do
				local deployed = {controller:getDeployedFighters(idx)}
				if deployed then
					total = total + #deployed
				end
			end
		end
		return total
	end
    for _, e in pairs(eligible) do
        local info = { entity = e, crew = e.crew, ideal = e.idealCrew }
        info.deficit = {}
        info.excess = {}
        info.deficitWorkforce = {}
        info.excessWorkforce = {}
        local haveWF = toWFMap(info.crew:getWorkforce())
        local needWF = toWFMap(info.ideal:getWorkforce())
        for _, p in ipairs(professions) do
            if p ~= Profession.None then
                local have = haveWF[p] or 0
                local need = needWF[p] or 0
                local diff = need - have
                info.deficitWorkforce[p] = math.max(0, math.ceil(diff))
                info.excessWorkforce[p] = math.max(0, math.floor(have - need))
                info.deficit[p] = info.deficitWorkforce[p]
            end
        end
		do
			local havePilots = haveWF[Profession.Pilot] or 0
			local pilotNeed = countTotalFightersIncludingDeployed(e.id)
			info.deficitWorkforce[Profession.Pilot] = math.max(0, math.ceil(pilotNeed - havePilots))
			info.excessWorkforce[Profession.Pilot] = math.max(0, math.floor(havePilots - pilotNeed))
			info.deficit[Profession.Pilot] = info.deficitWorkforce[Profession.Pilot]
		end
        local members = info.crew:getMembers()
        local noneCount = 0
        for man, num in pairs(members) do
            if man.profession.value == Profession.None then
                noneCount = noneCount + (num or 0)
            end
        end
        info.allrounderCount = noneCount
        info.excess[Profession.None] = math.max(0, noneCount - safetyReserveAllrounders)
        info.deficit[Profession.None] = math.max(0, safetyReserveAllrounders - noneCount)
        local key = tostring(e.index)
        shipInfo[key] = info
        if targetEntityId and e.id and e.id == targetEntityId then
            targetIndexStr = key
        end
    end
    local function doTransfer(fromE, toE, amount, crewman)
        if amount <= 0 then return 0 end
        local movedTotal = 0
        for _, rank in pairs({CrewRank.None, CrewRank.Sergeant, CrewRank.Lieutenant, CrewRank.Colonel}) do
            if amount <= 0 then break end
            crewman.rank = rank
            local removed = fromE:removeCrew(amount, crewman) or 0
            if removed > 0 then
                toE:addCrew(removed, crewman)
                amount = amount - removed
                movedTotal = movedTotal + removed
            end
        end
        return movedTotal
    end
    local function transferPilotsEnumerating(fromE, toE, amount)
        if amount <= 0 then return 0 end
        local moved = 0
        local members = fromE.crew:getMembers()
        for man, num in pairs(members) do
            if amount <= 0 then break end
            if man.profession.value == CrewProfessionType.Pilot then
                local take = math.min(amount, num or 0)
                if take > 0 then
                    local removed = fromE:removeCrew(take, man) or 0
                    if removed > 0 then
                        toE:addCrew(removed, man)
                        amount = amount - removed
                        moved = moved + removed
                    end
                end
            end
        end
        return moved
    end
    local showTransfers = true
    if foreman and foreman.showCrewTransfers == false then showTransfers = false end
    local showDebug = foreman and foreman.debugCrewBalance == true
    local function profName(p)
        local cp = CrewProfession(p)
        return cp:name(cp)
    end
    local function shipName(e)
        return e.name or tostring(e.index)
    end
    if showDebug then
        local abbrev = {
            [CrewProfessionType.Engine] = "Eng",
            [CrewProfessionType.Repair] = "Rep",
            [CrewProfessionType.Gunner] = "Gun",
            [CrewProfessionType.Miner] = "Min",
            [CrewProfessionType.Security] = "Sec",
            [CrewProfessionType.Attacker] = "Atk",
            [CrewProfessionType.Pilot] = "Pil",
        }
        for _, s in pairs(shipInfo) do
            local partsDef, partsEx = {}, {}
            for p, v in pairs(s.deficitWorkforce) do
                if v and v > 0 then table.insert(partsDef, string.format("%s=%d", abbrev[p] or tostring(p), v)) end
            end
            for p, v in pairs(s.excessWorkforce) do
                if v and v > 0 then table.insert(partsEx, string.format("%s=%d", abbrev[p] or tostring(p), v)) end
            end
            local name = s.entity.name or tostring(s.entity.index)
            local line = string.format("[CrewDbg] %s | Allr=%d | DefWF: %s | ExWF: %s",
                name, s.allrounderCount or 0, table.concat(partsDef, ","), table.concat(partsEx, ","))
            sector:broadcastChatMessage("Foreman", ChatMessageType.Information, line)
        end
    end
    local totalMoved = 0
    local receiversIter
    if targetIndexStr and shipInfo[targetIndexStr] then
        receiversIter = { shipInfo[targetIndexStr] }
    else
        receiversIter = shipInfo
    end
    for _, receiver in pairs(receiversIter) do
        for _, p in ipairs(professions) do
            if p ~= Profession.None then
                local need = receiver.deficitWorkforce[p] or 0
                if need > 0 then
                    for _, donor in pairs(shipInfo) do
                        if donor.entity.index ~= receiver.entity.index then
                            local donorExcessWF = donor.excessWorkforce[p] or 0
                            if donorExcessWF > 0 and need > 0 then
                                local takeNE = math.min(need, donorExcessWF)
                                local movedNE = doTransfer(donor.entity, receiver.entity, takeNE, CrewMan(p, false, 1))
                                if movedNE > 0 then
                                    need = need - movedNE
                                    donorExcessWF = math.max(0, donorExcessWF - movedNE)
                                    donor.excessWorkforce[p] = donorExcessWF
                                    totalMoved = totalMoved + movedNE
                                    if showTransfers then
                                        sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                                            string.format("%s: moved %d %s -> %s", shipName(donor.entity), movedNE, profName(p), shipName(receiver.entity)))
                                    end
                                end
                                if need > 0 and donorExcessWF > 0 then
                                    local takeEXByWF = math.min(need, donorExcessWF)
                                    local takeEX = math.ceil(takeEXByWF / 2)
                                    local movedEX = doTransfer(donor.entity, receiver.entity, takeEX, CrewMan(p, true, 1))
                                    if movedEX > 0 then
                                        need = math.max(0, need - movedEX * 2)
                                        donorExcessWF = math.max(0, donorExcessWF - movedEX * 2)
                                        donor.excessWorkforce[p] = donorExcessWF
                                        totalMoved = totalMoved + movedEX
                                        if showTransfers then
                                            sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                                                string.format("%s: moved %d Expert %s -> %s", shipName(donor.entity), movedEX, profName(p), shipName(receiver.entity)))
                                        end
                                    end
                                end
                            end
                        end
                    end
                    receiver.deficitWorkforce[p] = need
                end
            end
        end
    end
    local function isConvertibleProfession(p)
        if foreman and type(foreman.convertibleProfessions) == "table" then
            return foreman.convertibleProfessions[p] == true
        end
        return p ~= CrewProfessionType.Pilot
    end
    local function convertAllroundersToProfession(receiverE, profession, amount)
        if amount <= 0 then return 0 end
        local converted = 0
        for _, rank in pairs({CrewRank.None, CrewRank.Sergeant, CrewRank.Lieutenant, CrewRank.Colonel}) do
            if amount <= 0 then break end
            local cmNone = CrewMan(Profession.None, false, 1)
            cmNone.rank = rank
            local removed = receiverE:removeCrew(amount, cmNone) or 0
            if removed > 0 then
                receiverE:addCrew(removed, CrewMan(profession, false, 1))
                amount = amount - removed
                converted = converted + removed
            end
        end
        return converted
    end
    for _, receiver in pairs(receiversIter) do
        for _, p in ipairs(professions) do
            if p ~= Profession.None and isConvertibleProfession(p) then
                local need = receiver.deficitWorkforce[p] or receiver.deficit[p] or 0
                while need > 0 do
                    local fulfilled = 0
                    for _, donor in pairs(shipInfo) do
                        if donor.entity.index ~= receiver.entity.index then
                            local avail = donor.excess[Profession.None] or 0
                            if avail > 0 then
                                local take = math.min(avail, need)
                                local moved = doTransfer(donor.entity, receiver.entity, take, CrewMan(Profession.None, false, 1))
                                if moved > 0 then
                                    donor.excess[Profession.None] = math.max(0, avail - moved)
                                    local converted = convertAllroundersToProfession(receiver.entity, p, moved)
                                    need = math.max(0, need - converted)
                                    fulfilled = fulfilled + converted
                                    totalMoved = totalMoved + converted
                                    if converted > 0 and showTransfers then
                                        sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                                            string.format("%s: moved %d Allrounder(s) -> %s as %s", shipName(donor.entity), converted, shipName(receiver.entity), profName(p)))
                                    end
                                end
                                if need <= 0 then break end
                            end
                        end
                    end
                    if fulfilled == 0 then break end
                end
            end
        end
    end
    for _, receiver in pairs(receiversIter) do
        local needPilots = receiver.deficitWorkforce[CrewProfessionType.Pilot] or 0
        if needPilots and needPilots > 0 then
			if depth == 0 then
				local recvHavePil = (toWFMap(Entity(receiver.entity.id).crew:getWorkforce())[CrewProfessionType.Pilot] or 0)
				local recvNeedPil = countTotalFightersIncludingDeployed(receiver.entity.id)
				sector:broadcastChatMessage("Foreman", ChatMessageType.Information,
					string.format("Target %s: pilots have=%d need=%d deficit=%d",
						shipName(receiver.entity), recvHavePil, recvNeedPil, needPilots))
			end
            for _, donor in pairs(shipInfo) do
                if donor.entity.index ~= receiver.entity.index and needPilots > 0 then
                    local donorExcess = donor.excessWorkforce[CrewProfessionType.Pilot] or 0
                    if donorExcess > 0 then
                        if depth == 0 then
                            sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                                string.format("Donor %s: pilot surplus=%d (have=%d need=%d)",
                                    shipName(donor.entity), donorExcess,
                                    (toWFMap(Entity(donor.entity.id).crew:getWorkforce())[CrewProfessionType.Pilot] or 0),
								(function() return countTotalFightersIncludingDeployed(donor.entity.id) end)()))
                        end
                        local takeNE = math.min(needPilots, donorExcess)
                        local movedNE = transferPilotsEnumerating(donor.entity, receiver.entity, takeNE)
                        if movedNE > 0 then
                            needPilots = needPilots - movedNE
                            donorExcess = math.max(0, donorExcess - movedNE)
                            donor.excessWorkforce[CrewProfessionType.Pilot] = donorExcess
                            totalMoved = totalMoved + movedNE
                            if showTransfers then
                                sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                                    string.format("%s: moved %d surplus Pilots -> %s", shipName(donor.entity), movedNE, shipName(receiver.entity)))
                            end
                        end
                        if needPilots > 0 and donorExcess > 0 then
                            local takeEX = math.min(needPilots, donorExcess)
                            local movedEX = transferPilotsEnumerating(donor.entity, receiver.entity, takeEX)
                            if movedEX > 0 then
                                needPilots = math.max(0, needPilots - movedEX)
                                donorExcess = math.max(0, donorExcess - movedEX)
                                donor.excessWorkforce[CrewProfessionType.Pilot] = donorExcess
                                totalMoved = totalMoved + movedEX
                                if showTransfers then
                                    sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                                        string.format("%s: moved %d Pilots -> %s", shipName(donor.entity), movedEX, shipName(receiver.entity)))
                                end
                            end
                        end
                    end
                end
            end
            receiver.deficitWorkforce[CrewProfessionType.Pilot] = needPilots
        end
    end
    for _, receiver in pairs(receiversIter) do
        local needPilots = receiver.deficitWorkforce[CrewProfessionType.Pilot] or 0
        if allowOverdrawPilots and needPilots and needPilots > 0 then
            local donors = {}
            for _, donor in pairs(shipInfo) do
                if donor.entity.index ~= receiver.entity.index then
				local donorWF = toWFMap(Entity(donor.entity.id).crew:getWorkforce())
				local donorPilots = donorWF[CrewProfessionType.Pilot] or 0
				local donorNeed = countTotalFightersIncludingDeployed(donor.entity.id)
                    local donorExcessPilots = math.max(0, donorPilots - donorNeed)
                    if donorExcessPilots > 0 then
                        table.insert(donors, { info = donor, pilots = donorExcessPilots })
                    end
                end
            end
            table.sort(donors, function(a, b) return a.pilots > b.pilots end)
            for _, d in ipairs(donors) do
                if needPilots <= 0 then break end
                local take = math.min(needPilots, d.pilots)
                local moved = transferPilotsEnumerating(d.info.entity, receiver.entity, take)
                if moved > 0 then
                    needPilots = math.max(0, needPilots - moved)
                    totalMoved = totalMoved + moved
                    if showTransfers then
                        sector:broadcastChatMessage("Foreman", ChatMessageType.Chatter,
                            string.format("%s: overdraw moved %d Pilots -> %s", shipName(d.info.entity), moved, shipName(receiver.entity)))
                    end
                end
            end
            receiver.deficitWorkforce[CrewProfessionType.Pilot] = needPilots
        end
    end
    local deficitsLeft = 0
    local checkList = eligible
    if targetIndexStr and shipInfo[targetIndexStr] then
        checkList = { shipInfo[targetIndexStr].entity }
    end
    for _, e in pairs(checkList) do
        local haveWF2 = toWFMap(Entity(e.id).crew:getWorkforce())
        local needWF2 = toWFMap(Entity(e.id).idealCrew:getWorkforce())
        for _, p in ipairs(professions) do
            if p ~= Profession.None then
                local have = haveWF2[p] or 0
                local need
				if p == Profession.Pilot then
					need = countTotalFightersIncludingDeployed(e.id)
				else
                    need = needWF2[p] or 0
                end
                local diff = need - have
                if diff > 0 then deficitsLeft = deficitsLeft + math.ceil(diff) end
            end
        end
    end
    if deficitsLeft > 0 and totalMoved > 0 and depth < 10 then
        local movedNext = CrewBalance.balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth + 1, onServer, foreman, fms) or 0
        totalMoved = totalMoved + movedNext
    end
    if depth == 0 then
        if totalMoved > 0 then
            sector:broadcastChatMessage("Foreman", ChatMessageType.Information, string.format("Balanced crew: moved %d crew between ships.", totalMoved))
        else
            sector:broadcastChatMessage("Foreman", ChatMessageType.Information, "Crew already balanced. No transfers needed.")
        end
    end
    return totalMoved
end
function CrewBalance.balanceCrewNow()
    if onClient() then
        local x, y = Sector():getCoordinates()
        local craft = Player().craft
        local targetId = craft and craft.id or nil
        local allowOverdrawPilots = false
        invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "balanceCrewForForemanShips", Player().craft.factionIndex, targetId, allowOverdrawPilots, 0)
        return
    end
end
function CrewBalance.toggleAutoBalanceCrew()
    autoBalanceCrew = not autoBalanceCrew
    if autoBalanceCrew then
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-balance crew enabled")
        end
    else
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-balance crew disabled")
        end
    end
end
function balanceCrewNow()
    CrewBalance.balanceCrewNow()
end
function toggleAutoBalanceCrew()
    CrewBalance.toggleAutoBalanceCrew()
end
return CrewBalance
