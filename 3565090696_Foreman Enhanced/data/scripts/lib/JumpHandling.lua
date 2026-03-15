local JumpHandling = {}
function JumpHandling.updateJumpHandling(factionData, timeStep, getCachedEntitiesByType, onServer, appTime, _escortJumpState)
    local function getStragglerTimeoutSeconds()
        local sec = 20
        if foreman and type(foreman.ignoreStragglersAfterSec) == "number" then
            sec = foreman.ignoreStragglersAfterSec
        end
        return sec
    end
    local function getMaxIgnoredStragglers()
        local n = 2
        if foreman and type(foreman.maxIgnoredStragglersPerShip) == "number" then
            n = foreman.maxIgnoredStragglersPerShip
        end
        return n
    end
    for factionIndex, fData in pairs(factionData) do
        for shipIndex, shipData in pairs(fData.ships) do
            local ship = Entity(Uuid(shipIndex))
            if not valid(ship) then goto continue end
            local ai = ShipAI(ship.index)
            local controller = FighterController(ship.id)
            local hangar = Hangar(ship.id)
            if not controller or not hangar then goto continue end
            local isJumping = ai.state == AIState.Jump
            if isJumping then
                if not shipData.jumpInitiated then
                    shipData.jumpInitiated = true
                    shipData.jumpStartTime = 0
                    shipData.fightersRecalled = false
                    for _, squadIndex in pairs({hangar:getSquads()}) do
                        controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                        local key = tostring(ship.index) .. ":" .. tostring(squadIndex)
                        if CombatManager._lastCombatState then CombatManager._lastCombatState[key] = "return" end
                        if CombatManager._combatAssignedTargets then CombatManager._combatAssignedTargets[key] = nil end
                    end
                end
                shipData.jumpStartTime = shipData.jumpStartTime + timeStep
                for otherShipIndex, otherShipData in pairs(fData.ships) do
                    if otherShipIndex ~= shipIndex then
                        local otherShip = Entity(Uuid(otherShipIndex))
                        if valid(otherShip) then
                            local otherHangar = Hangar(otherShip.id)
                            local otherController = FighterController(otherShip.id)
                            if otherHangar and otherController then
                                for _, squadIndex in pairs({otherHangar:getSquads()}) do
                                    otherController:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                                end
                            end
                        end
                    end
                end
                local allFightersDocked = true
                for _, squadIndex in pairs({hangar:getSquads()}) do
                    local deployedFighters = {controller:getDeployedFighters(squadIndex)}
                    if #deployedFighters > 0 then
                        allFightersDocked = false
                        break
                    end
                end
                if allFightersDocked and not shipData.fightersRecalled then
                    shipData.fightersRecalled = true
                end
                shipData.isJumping = true
                shipData.harvest = false
                shipData.salvage = false
                shipData.isActive = false
                fData.salvageStandbyMode = false
				local allForemanShipsReady = true
				for otherShipIndex, otherData in pairs(fData.ships) do
					local other = Entity(Uuid(otherShipIndex))
					if valid(other) then
						local otherHangar = Hangar(other.id)
						local otherCtrl = otherHangar and FighterController(other.id) or nil
						if otherCtrl and otherHangar then
							local deployedCount = 0
							for _, sq in pairs({otherHangar:getSquads()}) do
								local deployed = {otherCtrl:getDeployedFighters(sq)}
								deployedCount = deployedCount + #deployed
							end
							if deployedCount > 0 then
								local waitedLongEnough = shipData.jumpWaitStartTime and ((appTime() - shipData.jumpWaitStartTime) >= getStragglerTimeoutSeconds())
								if not (waitedLongEnough and deployedCount <= getMaxIgnoredStragglers()) then
									allForemanShipsReady = false
								end
							end
						end
					end
					if not allForemanShipsReady then break end
				end
				if not allForemanShipsReady then
					for _, sq in pairs({hangar:getSquads()}) do
						controller:setSquadOrders(sq, FighterOrders.Return, Uuid())
					end
					ship:blockHyperspace(1.5)
					if onServer() and not shipData.jumpHoldAnnounced then
						if not shipData.jumpWaitStartTime then
							shipData.jumpWaitStartTime = appTime()
						elseif appTime() - shipData.jumpWaitStartTime > 1.0 then
							shipData.jumpHoldAnnounced = true
							Sector():broadcastChatMessage(ship, ChatMessageType.Chatter,
								string.format("Holding jump for fleet to dock fighters..."))
						end
					end
				else
					if shipData.jumpHoldAnnounced then
						shipData.jumpHoldAnnounced = false
					end
					if shipData.jumpWaitStartTime then
						shipData.jumpWaitStartTime = nil
					end
				end
            else
                if shipData.jumpInitiated then
                    shipData.jumpInitiated = false
                    shipData.jumpStartTime = 0
                    shipData.fightersRecalled = false
                    shipData.isJumping = false
                end
            end
            ::continue::
        end
    end
    if onServer() then
        local allShips = getCachedEntitiesByType(EntityType.Ship)
        for _, s in pairs(allShips) do
            if s.playerOrAllianceOwned then
                local hangar = Hangar(s.id)
                local controller = hangar and FighterController(s.id) or nil
                if controller then
                    local fi = s.factionIndex
                    local inForeman = factionData[fi] and factionData[fi].ships[tostring(s.index)] ~= nil
                    if not inForeman then
                        local ai = ShipAI(s.index)
                        if ai and ai.state == AIState.Jump then
                            local st = _escortJumpState[s.index] or { jumpInitiated = false }
                            if not st.jumpInitiated then
                                st.jumpInitiated = true
                                for _, squadIndex in pairs({hangar:getSquads()}) do
                                    controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                                end
                            end
                            _escortJumpState[s.index] = st
                        else
                            local st = _escortJumpState[s.index]
                            if st and st.jumpInitiated then
                                st.jumpInitiated = false
                                _escortJumpState[s.index] = st
                            end
                        end
                    end
                end
            end
        end
    end
end
function JumpHandling.onJump(shipId)
    return
end
return JumpHandling
