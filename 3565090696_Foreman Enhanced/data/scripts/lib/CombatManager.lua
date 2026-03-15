package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CombatManager = {}
CombatManager._combatAssignedTargets = {}
CombatManager._retargetCooldown = {}
CombatManager._noTargetTimer = {}
CombatManager._lastCombatState = {}
CombatManager._targetDiversityCache = {}
CombatManager._targetDiversityCacheAge = 0
CombatManager._targetDiversityCacheMaxAge = 0.5
CombatManager._returnMessageDelay = 0
CombatManager._returnMessageCounter = 0

function CombatManager.invalidateTargetDiversityCache()
    CombatManager._targetDiversityCache = {}
    CombatManager._targetDiversityCacheAge = 0
end

function CombatManager.updateCombat(factionData, DEBUG_COMBAT_MESSAGES)
    for factionIndex, data in pairs(factionData) do
        for shipIndex, _ in pairs(data.ships) do
            local ship = Entity(Uuid(shipIndex))
            if not valid(ship) then goto continue end
            local controller = FighterController(ship.id)
            local hangar = Hangar(ship.id)
            if not controller or not hangar then goto continue end
            local combatSquads = CombatUtils.getSquadsWithCombatFighters(ship.id)
            if getTableLength(combatSquads) == 0 then goto continue end
            local shipData = factionData[factionIndex].ships[tostring(shipIndex)]
            if shipData and shipData.isJumping then
                goto continue
            end
            
            -- Combat system only operates on actual combat fighters (WeaponCategory.Armed)
            -- No need to filter out salvage squads since getSquadsWithCombatFighters already excludes them
            if not CombatManager._combatAssignedTargets then CombatManager._combatAssignedTargets = {} end
            if not CombatManager._retargetCooldown then CombatManager._retargetCooldown = {} end
            if not CombatManager._noTargetTimer then CombatManager._noTargetTimer = {} end
            local ctx = CombatUtils.buildCombatContextForShip(ship)
            if not ctx then goto continue end
            for _, squadIndex in pairs(combatSquads) do
                local key = tostring(ship.index) .. ":" .. tostring(squadIndex)
                local currentId = CombatManager._combatAssignedTargets[key]
                local best = CombatUtils.getBestHostileTargetForSquad(shipIndex, squadIndex, currentId, CombatUtils.analyzeFighterWeaponCapabilities, CombatUtils.getBestHostileTargetForShip, CombatManager._combatAssignedTargets, CombatManager._targetDiversityCache, CombatManager._targetDiversityCacheAge, CombatManager._targetDiversityCacheMaxAge, DEBUG_COMBAT_MESSAGES)
                if best then
                    controller:setSquadOrders(squadIndex, FighterOrders.Attack, best.id)
                    if CombatManager._combatAssignedTargets[key] ~= tostring(best.index) then
                        CombatManager.invalidateTargetDiversityCache()
                    end
                    CombatManager._combatAssignedTargets[key] = tostring(best.index)
                    local cd = CombatManager._retargetCooldown[key] or 0
                    if cd > 0 then
                        CombatManager._retargetCooldown[key] = math.max(0, cd - 1)  -- Fixed: decrement by 1 since we update every 1 second
                    end
                    if currentId ~= tostring(best.index) and (CombatManager._retargetCooldown[key] or 0) <= 0 then
                        if onServer() and DEBUG_COMBAT_MESSAGES then
                            if currentId then
                                local current = Entity(Uuid(currentId))
                                if valid(current) then
                                    local hp = best.durability and best.maxDurability and best.maxDurability > 0 and (best.durability / best.maxDurability) or 1
                                    local curHp = current.durability and current.maxDurability and current.maxDurability > 0 and (current.durability / current.maxDurability) or 1
                                    local shield = best.shield and best.maxShield and best.maxShield > 0 and (best.shield / best.maxShield) or 1
                                    local curShield = current.shield and current.maxShield and current.maxShield > 0 and (current.shield / current.maxShield) or 1
                                    if math.abs(hp - curHp) < 0.2 then
                                        Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, string.format("[FOREMAN DEBUG] Ship %s Squad %d: TARGET CHANGE from %s (%.1f%% HP, %.1f%% Shield) to %s (%.1f%% HP, %.1f%% Shield)", 
                                            ship.name, squadIndex, current.name, curHp * 100, curShield * 100, best.name, hp * 100, shield * 100))
                                    else
                                        Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, string.format("[FOREMAN DEBUG] Ship %s Squad %d: TARGET CHANGE from %s (%.1f%% HP) to %s (%.1f%% HP)", 
                                            ship.name, squadIndex, current.name, curHp * 100, best.name, hp * 100))
                                    end
                                end
                            else
                                local hp = best.durability and best.maxDurability and best.maxDurability > 0 and (best.durability / best.maxDurability) or 1
                                local shield = best.shield and best.maxShield and best.maxShield > 0 and (best.shield / best.maxShield) or 1
                                Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, string.format("[FOREMAN DEBUG] Ship %s Squad %d: NEW TARGET assigned: %s (%.1f%% HP, %.1f%% Shield)", 
                                    ship.name, squadIndex, best.name, hp * 100, shield * 100))
                            end
                        end
                        CombatManager._retargetCooldown[key] = 3
                    end
                    if not CombatManager._lastCombatState then CombatManager._lastCombatState = {} end
                    if CombatManager._lastCombatState[key] ~= "attack" then
                        local fighters = {controller:getDeployedFighters(squadIndex)}
                        if #fighters > 0 then
                            local cat = hangar:getSquadMainWeaponCategory(squadIndex)
                            if cat == WeaponCategory.Salvaging then
                                fighterChatterMessage(fighters[1], getRandomSalvageEngageLine())
                            else
                                fighterChatterMessage(fighters[1], getRandomCombatEngageLine())
                            end
                        end
                        -- Reset return message counter when starting new combat
                        CombatManager._returnMessageCounter = 0
                    end
                    CombatManager._lastCombatState[key] = "attack"
                else
                     if not CombatManager._noTargetTimer[key] then
                         CombatManager._noTargetTimer[key] = 8  -- Wait 8 seconds before recalling
                     else
                         CombatManager._noTargetTimer[key] = CombatManager._noTargetTimer[key] - 1  -- Decrement by update interval (1 second)
                                                 if CombatManager._noTargetTimer[key] <= 0 then
                            if onServer() and DEBUG_COMBAT_MESSAGES then
                                Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, string.format("[FOREMAN DEBUG] Ship %s Squad %d: No targets - RECALLING fighters after 8s delay", ship.name, squadIndex))
                            end
                            controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                            if not CombatManager._lastCombatState then CombatManager._lastCombatState = {} end
                            if CombatManager._lastCombatState[key] ~= "return" then
                                local fighters = {controller:getDeployedFighters(squadIndex)}
                                if #fighters > 0 then
                                    -- Only some fighters speak sometimes (like regular chatter)
                                    if random():getFloat(0, 1) < 0.1 then -- 20% chance to speak
                                        local cat = hangar:getSquadMainWeaponCategory(squadIndex)
                                        local message = ""
                                        if cat == WeaponCategory.Salvaging then
                                            message = getRandomSalvageReturnLine()
                                        else
                                            message = getRandomCombatReturnLine()
                                        end
                                        
                                        -- Stagger return messages to prevent spam
                                        local delay = CombatManager._returnMessageCounter * 0.3 -- 0.3 seconds between each message
                                        CombatManager._returnMessageCounter = CombatManager._returnMessageCounter + 1
                                        
                                        deferredCallback(delay, function()
                                            if valid(Entity(fighters[1])) then
                                                fighterChatterMessage(fighters[1], message)
                                            end
                                        end)
                                    end
                                end
                            end
                            CombatManager._lastCombatState[key] = "return"
                            CombatManager._combatAssignedTargets[key] = nil
                            CombatManager._retargetCooldown[key] = 0
                            CombatManager._noTargetTimer[key] = nil
                        end
                    end
                end
            end
            ::continue::
        end
    end
end
function CombatManager.cleanupCombatState(shipIndex)
    if not CombatManager._combatAssignedTargets then return end
    for key, _ in pairs(CombatManager._combatAssignedTargets) do
        if string.find(key, tostring(shipIndex) .. ":") then
            CombatManager._combatAssignedTargets[key] = nil
            if CombatManager._retargetCooldown then
                CombatManager._retargetCooldown[key] = nil
            end
            if CombatManager._noTargetTimer then
                CombatManager._noTargetTimer[key] = nil
            end
            if CombatManager._lastCombatState then
                CombatManager._lastCombatState[key] = nil
            end
        end
    end
end
return CombatManager

