package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("galaxy")
include ("randomext")
include ("stringutility")
include ("player")
include ("relations")

ESCCUtil = include("esccutil")

local Placer = include ("placer")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local SpawnUtility = include ("spawnutility")
local EventUT = include ("eventutility")
local ITUtil = include("increasingthreatutility")

local piratefaction = nil
local ships = {}
local pirate_reserves = {}
local remaining_executioners = 0
local decapTargetPlayer = nil
local decapTargetAlliance = nil
local decapHatredLevel = 0

local participants = {}

--Some consts.
local decap_taunts = {
    "Target verified. Commencing hostilities.",
    "At the end of the broken path lies death, and death alone.",
    "There's nowhere left for you to run.",
    "Endless is the path that leads you from hell.",
    "Honed is the blade that severs the villain's head.",
    "This is the end for you.",
    "This is the end of the road for you. I think you understand why.",
    "You think it's your right to choose who lives and dies?",
    "Time to cut the head from the beast.",
    "There's nowhere to run!",
    "You die here!",
    "We'll decorate this sector with your strewn corpses!",
    "Go down, you murderer!",
    "An eye for an eye!"
}
local exit_taunts = {
    "This is not war anymore.",
    "You are not our adversary.",
    "Do not mistake this for mercy.",
    "We leave you to rot in your pathetic existence.",
    "Someday, we'll kill you too. But not here. Not today.",
    "Enjoy your unearned reprieve."
}

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace DecapStrike
DecapStrike = {}
DecapStrike.attackersGenerated = false

DecapStrike._Debug = 0

local _ActiveMods = Mods()
DecapStrike._HETActive = false

for _, _Xmod in pairs(_ActiveMods) do
	if _Xmod.id == "1821043731" then --HET
		DecapStrike._HETActive = true
	end
end

if onServer() then
    --Keep a structure roughly similar to other events that way we can expand this if needed.
    function DecapStrike.secure()
        local _MethodName = "Secure"
        DecapStrike.Log(_MethodName, "securing decap strike")

        DecapStrike.patchPirateFaction()

        return {
            pirate_reserves = pirate_reserves, 
            remainingexecutioners = remaining_executioners, 
            decaptarget = decapTargetPlayer, 
            decapTargetAlliance = decapTargetAlliance, 
            decaphatred = decapHatredLevel, 
            ships = ships, 
            piratefaction = piratefaction.index
        }
    end

    function DecapStrike.restore(data)
        local _MethodName = "Restore"
        DecapStrike.Log(_MethodName, "restoring decap strike")
        pirate_reserves = data.pirate_reserves
        remaining_executioners = data.remainingexecutioners
        decapTargetPlayer = data.decaptarget
        decapTargetAlliance = data.decapTargetAlliance
        decapHatredLevel = data.decaphatred
        ships = data.ships
        piratefaction = Faction(data.piratefaction)

        DecapStrike.patchPirateFaction()
    end

    function DecapStrike.initialize()
        local _MethodName = "Initialize"
        if not _restoring then
            local _Sector = Sector()
            DecapStrike.Log(_MethodName, "Initializing.")

            local generator = AsyncPirateGenerator(DecapStrike, DecapStrike.onPiratesGenerated)
            piratefaction = generator:getPirateFaction()

            local ITPlayers = ITUtil.getSectorPlayersByHatred(piratefaction.index)

            if not EventUT.attackEventAllowed() then
                DecapStrike.Log(_MethodName, "event not allowed - cancelling decapitation strike")
                ITUtil.unpauseEvents()

                --Pick a random player. If that player is hated enough, initiate an attack against them elsewhere.
                --I JUST REALIZED I DON'T NEED TO ACCOUNT FOR 0 PLAYERS BECAUSE THIS IS PLAYER BASED EVENT! YEAH
                local _RandomPlayer = randomEntry(ITPlayers)
                local _xPlayer = _RandomPlayer.player
                local _Attempts = _xPlayer:getValue("_increasingthreat_oos_attack_attempts")
                local x, y = _Sector:getCoordinates()

                if _Attempts == 0 then
                    --Unlike the normal pirate attacks, decapitation strikes will always launch an attack against another sector.
                    DecapStrike.Log(_MethodName, "Attack event not allowed. Attacking the player elsewhere.")
                    local _Interdict = { x = x, y = y }
                    _xPlayer:addScriptOnce("events/passiveplayerattackstarter.lua", _Interdict)
                end

                terminate()
                return
            end

            --If the pirate faction is craven, add a chance to abort the attack if there's AI defenders.
            local _Craven = piratefaction:getTrait("craven")
            if _Craven and _Craven >= 0.25 then
                local _Galaxy = Galaxy()
                local _X, _Y = _Sector:getCoordinates()
                local _Controller = _Galaxy:getControllingFaction(_X, _Y)
                if _Controller then
                    if _Controller.isAIFaction then
                        local _Rgen = ESCCUtil.getRand()
                        if _Rgen:getInt(1, 5) == 1 then
                            DecapStrike.Log(_MethodName, "Pirates decided to abort the attack due to cowardice.")
                            termiante()
                            return
                        end
                    end
                end
            end

            --Decap strikes work as follows:
            --Preference is given to players by how much hatred they have. Players are sorted from most to least hated.
            --A decap strike cannot be done more than once every 3-6 hours. This amount is chosen at random. This, however is on a PER PLAYER basis.
            --i.e. if KnifeHeart and Cy are both in the same sector and KnifeHeart had a decap strike in the last hour, Cy can still get hit by one.
            --At least one player in the sector must have at least 50 notoriety and 200 hatred to trigger a decapitation strike event.
            --Even if both players are eligible for a decap strike event, it starts at a 25% chance at 200 hatred, and caps at a 75% chance at 1000.
            --So you might still get lucky and skip some decapitation strikes.
            --Executioner strength is based on the hatred value of the targeted player.
            --Number of executioners spawn based on the number of ships that the targeted player owns in the sector. It is 1 ex per 3 ships up to 16, then 1 per 2 afterwards.
            --BUT the pirates aren't stupid. They will add one standard ship to the list of ships for each ship owned by a player who is NOT the targeted player.
            --Update 2/26/2022 - Moved the spot where the player is retrieved up to line 112 in order to launch passive attacks against them somewhere else.
            local triggerDecapStrike = false
            local serverTime = Server().unpausedRuntime
            for _, p in pairs(ITPlayers) do
                if p.hatred >= 200 and p.notoriety >= 50 then
                    --eligible for a decap. Check to see when the last decap strike they got hit with was.
                    local nextDecapTime = p.player:getValue("_increasingthreat_next_decap") or -1
                    DecapStrike.Log(_MethodName, "next decap OK at " .. tostring(nextDecapTime) .. " <= current time is: " .. tostring(serverTime))
                    if serverTime >= nextDecapTime or nextDecapTime == -1 then
                        local chance = 25 + math.min(50, math.floor(math.max(0, p.hatred - 200) / 16))
                        DecapStrike.Log(_MethodName, "Chance to initiate decap is " .. tostring(chance) .. " chance")
                        if math.random(100) < chance then
                            --This is it. We set off a decap strike here.
                            triggerDecapStrike = true
                            decapTargetPlayer = p.player
                            decapHatredLevel = p.hatred
                            local nextDecapHrs = math.random(3,6)
                            if DecapStrike._HETActive then
                                nextDecapHrs = nextDecapHrs * 0.6
                            end
                            local _Vengeful = piratefaction:getTrait("vengeful")
                            if _Vengeful and _Vengeful >= 0.25 then
                                DecapStrike.Log(_MethodName, "Pirates are Vengeful. Decreasing time until next decap strike happens.")
                                local _VengefulFactor = 1.0
                                if _Vengeful >= 0.25 then
                                    _VengefulFactor = 0.8
                                end
                                if _Vengeful >= 0.75 then
                                    _VengefulFactor = 0.7
                                end
                                nextDecapHrs = nextDecapHrs * _VengefulFactor
                            end
                            DecapStrike.Log(_MethodName, "Next decap will be in " .. tostring(nextDecapHrs) .. " decap hatred level is " .. tostring(decapHatredLevel) .. " || " .. tostring(type(decapHatredLevel)))
                            local nextDecap = serverTime + (3600 * nextDecapHrs)
                            p.player:setValue("_increasingthreat_next_decap", nextDecap)
                            break
                        end
                    else
                        DecapStrike.Log(_MethodName, p.player.name .. " was targeted by a decap strike recently. Checking next potential target.")
                    end
                else
                    DecapStrike.Log(_MethodName, "Player hatred only " .. tostring(p.hatred) .. " and notoriety is only " .. tostring(p.notoriety) .. " - player isn't eligible for a decap.")
                end
            end

            if triggerDecapStrike then
                --Count target player ships and non-target player ships.
                local targetPlayerShips = 0
                local nonTargetPlayerShips = 0
                local factions = {_Sector:getPresentFactions()}

                for _, index in pairs(factions) do
                    local faction = Faction(index)

                    if faction then
                        local crafts = {_Sector:getEntitiesByFaction(index)}

                        for _, craft in pairs(crafts) do
                            if craft.isShip or craft.isStation then
                                if faction.isPlayer then
                                    if index == decapTargetPlayer.index then
                                        DecapStrike.Log(_MethodName, "Ship belongs to target of decap strike. Increasing target player ships value.")
                                        targetPlayerShips = targetPlayerShips + 1
                                    else
                                        DecapStrike.Log(_MethodName, "Ship does not belong to target. Increasing non target player ships value.")
                                        nonTargetPlayerShips = nonTargetPlayerShips + 1
                                    end
                                end
                                if faction.isAlliance then
                                    local allx = Alliance(faction.index)
                                    if allx:contains(decapTargetPlayer.index) then
                                        DecapStrike.Log(_MethodName, "Alliance contains targeted player. Use this to count their ships.")
                                        decapTargetAlliance = faction
                                        targetPlayerShips = targetPlayerShips + 1
                                    else
                                        nonTargetPlayerShips = nonTargetPlayerShips + 1
                                    end
                                end
                                if faction.isAIFaction then
                                    --AI ships / stations count double since they get cheater buffs. (i.e. damage multipliers)
                                    nonTargetPlayerShips = nonTargetPlayerShips + 2
                                end
                            end
                        end
                    end
                end
                DecapStrike.Log(_MethodName, "Ships owned by target: " .. targetPlayerShips)
                DecapStrike.Log(_MethodName, "Ships not owned by target: " .. nonTargetPlayerShips)

                --subtract 1 from this immediately because we are spawning an executioner directly in this block of code.
                remaining_executioners = math.ceil(math.min(4, targetPlayerShips / 4) + (math.max(0, targetPlayerShips - 16) / 2)) - 1
                DecapStrike.Log(_MethodName, "spawning " .. remaining_executioners .. " plus one.")
                local numberOfOtherShips = nonTargetPlayerShips

                local _Brutish = piratefaction:getTrait("brutish")
                if _Brutish and _Brutish >= 0.25 then
                    numberOfOtherShips = math.max(5, math.floor(numberOfOtherShips * 1.3))
                end

                if DecapStrike._HETActive then
                    numberOfOtherShips = math.floor(numberOfOtherShips * 1.5) --50% more ships.
                    remaining_executioners = remaining_executioners + 1 --1 more executioner
                end

                local lowThreatTable = ITUtil.getLowThreatTable()
                local highThreatTable = ITUtil.getHatredTable(decapHatredLevel)
                for _ = 1, numberOfOtherShips do
                    table.insert(pirate_reserves, highThreatTable[math.random(#highThreatTable)])
                end

                --If the player is at less than 400 hatred, cap # of executioners at 5
                --After that, go nuts.
                if decapHatredLevel <= 400 then
                    remaining_executioners = math.min(remaining_executioners, 5)
                end

                --If they hate you enough and less than 5 executioners are coming, bump up the # by 2, but not to more than 5.
                if decapHatredLevel > 1000 and remaining_executioners < 5 then
                    remaining_executioners = math.min(remaining_executioners + 2, 5)
                end

                --Create the first wave. It always consists of an executioner.
                local attackingShips = {}
                table.insert(attackingShips, "Executioner")
                local firstWaveExtras = math.random(2, 4)
                for _ = 1, firstWaveExtras do
                    if next(pirate_reserves) ~= nil then
                        local xShip = table.remove(pirate_reserves)
                        table.insert(attackingShips, xShip)
                    else
                        table.insert(attackingShips, lowThreatTable[math.random(#lowThreatTable)])
                    end
                end

                generator:startBatch()

                local posCounter = 1
                local pirate_positions = generator:getStandardPositions(#attackingShips, 300)
                for _, p in pairs(attackingShips) do
                    if p == "Executioner" then
                        generator:createScaledExecutioner(pirate_positions[posCounter], decapHatredLevel)
                    else
                        generator:createScaledPirateByName(p, pirate_positions[posCounter])
                    end
                    posCounter = posCounter + 1
                end

                generator:endBatch()

                local alertstring = string.format("%s is being targeted by a pirate attack"%_t, decapTargetPlayer.name)
                _Sector:broadcastChatMessage("Server"%_t, 2, alertstring .. "!")
                AlertAbsentPlayers(2, alertstring .. " in sector \\s(%1%:%2%)!"%_t, _Sector:getCoordinates())
            else
                DecapStrike.Log(_MethodName, "no decap strike. Terminating the event.")
                ITUtil.unpauseEvents()
                terminate()
                return
            end
        end
    end

    function DecapStrike.getUpdateInterval()
        return 10
    end

    --Created Callbacks
    function DecapStrike.onPiratesGenerated(generated)
        -- add enemy buffs
        SpawnUtility.addEnemyBuffs(generated) --Covered IT Extra Scripts
        local _WilyTrait = piratefaction:getTrait("wily") or 0
        SpawnUtility.addITEnemyBuffs(generated, _WilyTrait, decapHatredLevel)

        for _, ship in pairs(generated) do
            if valid(ship) then -- this check is necessary because ships could get destroyed before this callback is executed
                ships[ship.index.string] = true
                ship:registerCallback("onDestroyed", "onShipDestroyed")
            end
        end

        for _, ship in pairs(generated) do
            local isexec = ship:getValue("is_executioner") or 0
            if isexec == 1 then
                Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, decap_taunts[math.random(#decap_taunts)])
                break
            end
        end

        -- resolve intersections between generated ships
        Placer.resolveIntersections(generated)

        DecapStrike.attackersGenerated = true
    end

    function DecapStrike.onNextPiratesGenerated(generated)
        -- add enemy buffs
        SpawnUtility.addEnemyBuffs(generated) --Covered IT Extra Scripts
        local _WilyTrait = piratefaction:getTrait("wily") or 0
        SpawnUtility.addITEnemyBuffs(generated, _WilyTrait, decapHatredLevel)

        for _, ship in pairs(generated) do
            if valid(ship) then -- this check is necessary because ships could get destroyed before this callback is executed
                ships[ship.index.string] = true
                ship:registerCallback("onDestroyed", "onShipDestroyed")
            end
        end

        -- resolve intersections between generated ships
        Placer.resolveIntersections(generated)

        DecapStrike.attackersGenerated = true
    end

    function DecapStrike.onShipDestroyed(shipIndex)

        ships[shipIndex.string] = nil

        local ship = Entity(shipIndex)
        local damagers = {ship:getDamageContributors()}
        for _, damager in pairs(damagers) do
            local faction = Faction(damager)
            if faction and (faction.isPlayer or faction.isAlliance) then
                participants[damager] = damager
            end
        end

        if #pirate_reserves == 0 and tablelength(ships) == 0 and remaining_executioners == 0 then
            DecapStrike.endEvent()
        end
    end

    function DecapStrike.update(timeStep)
        local _MethodName = "Update"
        DecapStrike.Log(_MethodName, "running decap strike update")
        if not DecapStrike.attackersGenerated then return end

        local _PiratesInSector = {Sector():getEntitiesByFaction(piratefaction)}
        local _PiratesInSectorCt = #_PiratesInSector

        local noShips = tablelength(ships)
        if noShips < 25 and _PiratesInSectorCt < 40 then
            local pirateBatch = {}
            if remaining_executioners > 0 then
                table.insert(pirateBatch, "Executioner")

                local lowThreatTable = ITUtil.getLowThreatTable()
                local WaveExtras = math.random(2, 4)
                for _ = 1, WaveExtras do
                    if next(pirate_reserves) ~= nil then
                        local xShip = table.remove(pirate_reserves)
                        table.insert(pirateBatch, xShip)
                    else
                        table.insert(pirateBatch, lowThreatTable[math.random(#lowThreatTable)])
                    end
                end
                remaining_executioners = remaining_executioners - 1
            end
            if #pirateBatch < 5 and #pirate_reserves > 0 then
                local ins = 5 - #pirateBatch
                --Keep # of ships from going above 25.
                if noShips + ins > 25 then
                    ins = 25 - noShips
                end
                for _ = 1, ins do
                    if next(pirate_reserves) ~= nil then
                        local xShip = table.remove(pirate_reserves)
                        table.insert(pirateBatch, xShip)
                    end
                end
            end

            local generator = AsyncPirateGenerator(DecapStrike, DecapStrike.onNextPiratesGenerated)
            generator:startBatch()

            local posCounter = 1
            local pirate_positions = generator:getStandardPositions(#pirateBatch, 300)
            for _, p in pairs(pirateBatch) do
                if p == "Executioner" then
                    generator:createScaledExecutioner(pirate_positions[posCounter], decapHatredLevel)
                else
                    generator:createScaledPirateByName(p, pirate_positions[posCounter])
                end
                posCounter = posCounter + 1
            end

            generator:endBatch()
        end

        local decapTargets = 0
        local crafts = {Sector():getEntitiesByFaction(decapTargetPlayer.index)}
        for _, c in pairs(crafts) do
            if c.isShip or c.isStation then
                decapTargets = decapTargets + 1
            end
        end

        if decapTargetAlliance then
            local acrafts = {Sector():getEntitiesByFaction(decapTargetAlliance.index)}
            for _, c in pairs(acrafts) do
                if c.isShip or c.isStation then
                    decapTargets = decapTargets + 1
                end
            end
        end

        local sentTaunt = false
        if decapTargets == 0 then
            local pcrafts = {Sector():getEntitiesByFaction(piratefaction.index)}
            pirate_reserves = {}
            ships = {}

            for _, pcraft in pairs(pcrafts) do
                if pcraft.isShip and not sentTaunt then
                    Sector():broadcastChatMessage(pcraft, ChatMessageType.Chatter, exit_taunts[math.random(#exit_taunts)])
                    sentTaunt = true
                end
                if pcraft.isShip then
                    pcraft:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
                end
            end
        end

        DecapStrike.Log(_MethodName, "pirate reserve count is " .. #pirate_reserves)
        DecapStrike.Log(_MethodName, "ship count remaining is " .. noShips)
        if #pirate_reserves == 0 and noShips == 0 and remaining_executioners == 0 then
            DecapStrike.endEvent()
        end
    end

    function DecapStrike.endEvent()
        local _MethodName = "End Event"
        DecapStrike.Log(_MethodName, "ending decap strike")

        local _IncreasedHatredFor = {}
        local players = {Sector():getPlayers()}

        for _, participant in pairs(participants) do
            local participantFaction = Faction(participant)

            if participantFaction then
                if participantFaction.isPlayer and not _IncreasedHatredFor[participantFaction.index] then
                    DecapStrike.Log(_MethodName, "Have not yet increased hatred for faction index " .. tostring(participantFaction.index) .. " - increasing hatred.")
                    DecapStrike.increaseHatred(participantFaction)
                    _IncreasedHatredFor[participantFaction.index] = true
                end
                if participantFaction.isAlliance then
                    local _Alliance = Alliance(participant)
                    for _, _Pl in pairs(players) do
                        if _Alliance:contains(_Pl.index) and not _IncreasedHatredFor[_Pl.index] then
                            DecapStrike.increaseHatred(_Pl)
                            _IncreasedHatredFor[_Pl.index] = true
                        else
                            DecapStrike.Log(_MethodName, "Have either increased hatred for faciton index " .. tostring(_Pl.index) .. " or they are not part of the alliance.")
                        end
                    end
                end
            end
        end

        terminate()
    end

    function DecapStrike.patchPirateFaction()
        if not piratefaction then
            --needed to patch an issue on Divine Reapers. Not sure why this happens but apparently my previous patch didn't fix it.
            local generator = AsyncPirateGenerator(DecapStrike, DecapStrike.onPiratesGenerated)
            piratefaction = generator:getPirateFaction()
        end
    end
end

--region #CLIENT / SERVER CALLS

function DecapStrike.increaseHatred(_Faction)
    local _MethodName = "Increase Hatred"
    local hatredindex = "_increasingthreat_hatred_" .. piratefaction.index
    local hatred = _Faction:getValue(hatredindex)
    local xmultiplier = 1
    local _Difficulty = GameSettings().difficulty
    if _Difficulty == Difficulty.Veteran then
        xmultiplier = 1.15
    elseif _Difficulty == Difficulty.Expert then
        xmultiplier = 1.3
    elseif _Difficulty > Difficulty.Expert then
        xmultiplier = 1.5
    end
    local hatredincrement = 15 * xmultiplier

    local _Tempered = piratefaction:getTrait("tempered")
    if _Tempered then
        local _TemperedFactor = 1.0
        if _Tempered >= 0.25 then
            _TemperedFactor = 0.8
        end
        if _Tempered >= 0.75 then
            _TemperedFactor = 0.7
        end
        DecapStrike.Log(_MethodName, "Faction is tempered - hatred multiplier is (" .. tostring(_TemperedFactor) .. ")")
        hatredincrement = hatredincrement * _TemperedFactor
    end
    hatredincrement = math.ceil(hatredincrement)

    if hatred then
        DecapStrike.Log(_MethodName, "hatred value is " .. hatred)
        hatred = hatred + hatredincrement
    else
        DecapStrike.Log(_MethodName, "hatred value is 0")
        hatred = hatredincrement
    end
    DecapStrike.Log(_MethodName, "new hatred value is " .. hatred)
    _Faction:setValue(hatredindex, hatred)
    if hatred >= 700 then
        DecapStrike.Log(_MethodName, "Hatred is greater than 700. Setting traits for pirates.")
        ITUtil.setIncreasingThreatTraits(piratefaction)
    end
end

function DecapStrike.Log(_MethodName, _Msg)
    if DecapStrike._Debug == 1 then
        print("[IT DecapStrike] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion