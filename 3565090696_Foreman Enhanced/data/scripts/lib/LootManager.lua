local LootManager = {}
local fighterLootPickUps = {} -- [tostring(loot.index)][factionIndex] = fighterIndex
local assignedFighters = {} -- [factionIndex][tostring(fighterIndex)] = loot.index

-- Loot debugging flag - set to true to enable debugging output
local LOOT_DEBUG_ENABLED = false
local goAfterLootChatterChange = 0.05
local pickupLootChatterChange = 0.05
local pickupWrongLootChatterChange = 0.05
local exoticLootPickUpChatterChange = 1
local goAfterLootChatterCooldown = 0
local goAfterLootChatterTimeLeft = 3
function LootManager.updateLootChatterTimer(timeStep)
    if goAfterLootChatterTimeLeft > 0 then
        goAfterLootChatterTimeLeft = goAfterLootChatterTimeLeft - timeStep
    end
end
function LootManager.clearFactionLootPickups(factionIndex, getTableLength)
    local keys = {}
    if fighterLootPickUps and getTableLength(fighterLootPickUps) > 0 then
        for i in pairs(fighterLootPickUps) do
            table.insert(keys, i)
        end
        for i=#keys, 1, -1 do
            if fighterLootPickUps[keys[i]][factionIndex] then
                fighterLootPickUps[keys[i]][factionIndex] = nil
            end
            if getTableLength(fighterLootPickUps[keys[i]]) == 0 then
                fighterLootPickUps[keys[i]] = nil
            end
        end
        local count = #keys
        for i=0, count do keys[i]=nil end
    end
    if assignedFighters and getTableLength(assignedFighters) > 0 then
        for i in pairs(assignedFighters) do
            table.insert(keys, i)
        end
        for i=#keys, 1, -1 do
            if assignedFighters[keys[i]] then
                assignedFighters[keys[i]] = nil
            end
        end
    end
end
function LootManager.checkLootForPickup(factionIndex, getCachedEntitiesByType, getTableLength, setFighterMoveOrder)
    local loots = getCachedEntitiesByType(EntityType.Loot)
    if LOOT_DEBUG_ENABLED then
        print("Foreman: LootManager.checkLootForPickup - found", getTableLength(loots), "loot entities for faction", factionIndex)
    end
    if getTableLength(loots) == 0 then
        return
    end
    local fighters = {Sector():getEntitiesByFaction(factionIndex)}
    local fightersNum = getTableLength(fighters)
    for i = getTableLength(fighters), 1, -1 do
        if fighters[i].type ~= EntityType.Fighter then
            table.remove(fighters, i)
            fightersNum = fightersNum - 1
        end
    end
    if LOOT_DEBUG_ENABLED then
        print("Foreman: LootManager.checkLootForPickup - found", fightersNum, "fighters for faction", factionIndex)
    end
    if fightersNum == 0 then
        if LOOT_DEBUG_ENABLED then
            print("Foreman: LootManager.checkLootForPickup - no fighters available, returning")
        end
        return
    end
    local newAssigns = 0
    local valuableLootCount = 0
    for _, loot in pairs(loots) do
        if loot:hasComponent(ComponentType.SystemUpgradeLoot) or loot:hasComponent(ComponentType.TurretLoot) then
            valuableLootCount = valuableLootCount + 1
            if fighterLootPickUps[tostring(loot.index)] == nil then
                local lootLocation = loot.translationf
                local closestDistance = math.huge
                local closestFighter = nil
                for _, fighter in pairs(fighters) do
                    local fighterAI = ReadOnlyFighterAI(fighter.id)
                    if Entity(fighterAI.mothershipId).fighterCargoPickup then
                        if assignedFighters[factionIndex] == nil then
                            assignedFighters[factionIndex] = {}
                        end
                        if assignedFighters[factionIndex][tostring(fighter.index)] == nil then
                            local distance = distance(lootLocation, fighter.translationf)
                            if distance < closestDistance then
                                closestDistance = distance
                                closestFighter = fighter
                            end
                        end
                    end
                end
                if closestFighter ~= nil then
                    if fighterLootPickUps[tostring(loot.index)] == nil then
                        fighterLootPickUps[tostring(loot.index)] = {}
                    end
                    newAssigns = newAssigns + 1
                    assignedFighters[factionIndex][tostring(closestFighter.index)] = loot.index
                    fighterLootPickUps[tostring(loot.index)][factionIndex] = closestFighter.index
                    setFighterMoveOrder(closestFighter.index, loot.index, true)
                end
                if #assignedFighters == fightersNum then break end
            end
        end
    end
    if LOOT_DEBUG_ENABLED then
        print("Foreman: LootManager.checkLootForPickup - found", valuableLootCount, "valuable loot items, made", newAssigns, "new assignments")
    end
end
function LootManager.setFighterMoveOrder(fighterIndex, lootIndex, bIgnoreMotherShip, bSquadOrdersChanged, getRandomGoAfterLootLine, fighterChatterMessage)
    local ai = FighterAI(fighterIndex)
    ai.ignoreMothershipOrders = bIgnoreMotherShip
    if bIgnoreMotherShip then
        local loot = Entity(lootIndex)
        local fighter = Sector():getEntity(fighterIndex)
        if loot == nil then
            ai.ignoreMothershipOrders = false
            ai:setOrders(FighterOrders.Defend, ai.mothershipId)
            return
        end
        local maxVelocity = DirectFlightPhysics(fighterIndex).maxVelocity * 40
        local dist = distance(loot.translationf, fighter.translationf) * 10
        local timeToTravel = dist / maxVelocity
        if timeToTravel > 3 then
            ai:setOrders(FighterOrders.Attack, loot.id)
            if not bSquadOrdersChanged then
                deferredCallback(timeToTravel, "setFighterFlyToLocation", fighterIndex, lootIndex)
            end
        else
            ai:setOrders(FighterOrders.FlyToLocation, loot.id)
        end
        if not bSquadOrdersChanged then
            if math.random() <= goAfterLootChatterChange and goAfterLootChatterTimeLeft <= 0 then
                goAfterLootChatterTimeLeft = goAfterLootChatterCooldown
                fighterChatterMessage(fighterIndex, getRandomGoAfterLootLine())
            elseif timeToTravel > 5 and math.random() <= 0.05 then
                fighterChatterMessage(fighterIndex, "Engaging boosters for " .. tostring(round(timeToTravel, 0)) .. " seconds")
            end
        end
    else
        Sector():broadcastChatMessage(fighter, ChatMessageType.Chatter, "Coming back")
        ai.ignoreMothershipOrders = false
        ai:setOrders(FighterOrders.Defend, ai.mothershipId)
    end
end
function LootManager.setFighterFlyToLocation(fighterIndex, lootIndex, getRandomLootPickedUpLine, getRandomWrongLootPickedUpLine, fighterChatterMessage)
    if not Entity(fighterIndex) then return end
    local factionIndex = Entity(fighterIndex).mothership.factionIndex
    local ai = FighterAI(fighterIndex)
    local loot = Entity(lootIndex)
    local f = assignedFighters[factionIndex]
    local pickup = nil
    if f then pickup = assignedFighters[factionIndex][tostring(fighterIndex)] end
    if loot == nil or pickup == nil then
        ai.ignoreMothershipOrders = false
        ai:setOrders(FighterOrders.Defend, ai.mothershipId)
        if assignedFighters[factionIndex] and assignedFighters[factionIndex][tostring(fighterIndex)] then
            assignedFighters[factionIndex][tostring(fighterIndex)] = nil
        end
        if fighterLootPickUps[tostring(lootIndex)] and fighterLootPickUps[tostring(lootIndex)][factionIndex] then
            fighterLootPickUps[tostring(lootIndex)][factionIndex] = nil
        end
        return
    end
    if tostring(loot.id) ~= tostring(ai.target) then
        Sector():broadcastChatMessage(fighter, ChatMessageType.Chatter, "Idk, coming back")
        ai.ignoreMothershipOrders = false
        ai:setOrders(FighterOrders.Defend, ai.mothershipId)
        assignedFighters[factionIndex][tostring(fighterIndex)] = nil
        fighterLootPickUps[tostring(lootIndex)][factionIndex] = nil
    else
        Sector():broadcastChatMessage(fighter, ChatMessageType.Chatter, "Going after loot - Normal speed")
        ai:setOrders(FighterOrders.FlyToLocation, loot.id)
    end
end
function LootManager.handleLootDrop(lootIndex, getTableLength, setFighterMoveOrder)
    local loot = Entity(lootIndex)
    local playerFactions = {Sector():getPresentFactions()}
    for i = getTableLength(playerFactions), 1, -1 do
        if Faction(playerFactions[i]).isAIFaction then
            table.remove(playerFactions, i)
        end
    end
    for _, factionIndex in pairs(playerFactions) do
        local fighters = {Sector():getEntitiesByFaction(factionIndex)}
        local fightersNum = getTableLength(fighters)
        local motherShips = {}
        for i = getTableLength(fighters), 1, -1 do
            if fighters[i].type ~= EntityType.Fighter then
                table.remove(fighters, i)
                fightersNum = fightersNum - 1
            else
                local motherShip = fighters[i].mothership
                if motherShip then
                    if motherShips[tostring(motherShip.index)] == nil then
                        motherShips[tostring(motherShip.index)] = false
                        for upgrade, permanent in pairs(ShipSystem(motherShip.index):getUpgrades()) do
                            if permanent and upgrade.script == "data/scripts/systems/foremansystem.lua" then
                                local success, ret, _, _, _, fighterPickUpLoot, _, _ = pcall(function()
                                    return motherShip:invokeFunction("data/scripts/systems/foremansystem.lua", "getBonuses", upgrade.seed.int32, upgrade.rarity, permanent)
                                end)
                                if success and ret == 0 and fighterPickUpLoot then
                                    motherShips[tostring(motherShip.index)] = true
                                    break
                                elseif not success then
                                    if LOOT_DEBUG_ENABLED then
                                        print("Foreman: Failed to get foreman system bonuses for mothership " .. tostring(motherShip.index) .. ": " .. tostring(ret))
                                    end
                                end
                            end
                        end
                    end
                    if motherShips[tostring(motherShip.index)] == false then
                        table.remove(fighters, i)
                        fightersNum = fightersNum - 1
                    end
                else
                    table.remove(fighters, i)
                    fightersNum = fightersNum - 1
                end
            end
        end
        if fightersNum == 0 then return end
        local dropLocation = loot.translationf
        local closestDistance = math.huge
        local closestFighter = nil
        for _, v in pairs(fighters) do
            if assignedFighters[factionIndex] == nil then
                assignedFighters[factionIndex] = {}
            end
            if assignedFighters[factionIndex][tostring(v.index)] == nil then
                local distance = distance(dropLocation, v.translationf)
                if distance < closestDistance then
                    closestDistance = distance
                    closestFighter = v
                end
            end
        end
        if closestFighter ~= nil then
            if fighterLootPickUps[tostring(loot.index)] == nil then
                fighterLootPickUps[tostring(loot.index)] = {}
            end
            assignedFighters[factionIndex][tostring(closestFighter.index)] = loot.index
            fighterLootPickUps[tostring(loot.index)][factionIndex] = closestFighter.index
            setFighterMoveOrder(closestFighter.index, loot.index, true)
        end
    end
end
function LootManager.onLootCollected(collectorIndex, lootIndex, getRandomLootPickedUpLine, getRandomWrongLootPickedUpLine, fighterChatterMessage)
    local fighterLootPickUp = fighterLootPickUps[tostring(lootIndex)]
    if fighterLootPickUp ~= nil then
        local factionIndex = Entity(collectorIndex).factionIndex
        if fighterLootPickUp[factionIndex] == nil then return end
        local entity = Entity(collectorIndex)
        if fighterLootPickUp[factionIndex] == collectorIndex then
            assignedFighters[factionIndex][tostring(entity.index)] = nil
            local ai = FighterAI(collectorIndex)
            ai.ignoreMothershipOrders = false
            ai:setOrders(FighterOrders.Defend, ai.mothershipId)
            if math.random() <= pickupLootChatterChange then
                fighterChatterMessage(collectorIndex, getRandomLootPickedUpLine())
            end
        else
            local ai = FighterAI(fighterLootPickUp[factionIndex])
            ai.ignoreMothershipOrders = false
            ai:setOrders(FighterOrders.Defend, ai.mothershipId)
            assignedFighters[tostring(fighterLootPickUp[factionIndex])] = nil
            if math.random() <= pickupWrongLootChatterChange then
                fighterChatterMessage(collectorIndex, getRandomWrongLootPickedUpLine())
            end
        end
        local keys = {}
        for i in pairs(assignedFighters) do
            table.insert(keys, i)
        end
        for i = getTableLength(keys), 1, -1 do
            for fighterId = getTableLength(assignedFighters[i]), 1, -1 do
                if assignedFighters[i][fighterId] == lootIndex then
                    local ai = FighterAI(fighterId)
                    ai.ignoreMothershipOrders = false
                    ai:setOrders(FighterOrders.Defend, ai.mothershipId)
                    assignedFighters[i][fighterId] = nil
                end
            end
        end
        fighterLootPickUps[tostring(lootIndex)] = nil
    end
end
function LootManager.getFighterLootPickUps()
    return fighterLootPickUps
end
function LootManager.getAssignedFighters()
    return assignedFighters
end
return LootManager
