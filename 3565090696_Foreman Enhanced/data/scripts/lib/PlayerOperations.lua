local PlayerOperations = {}
function PlayerOperations.getOperationsStatus(playerIndex, factionIndex, factionData)
    local fData = factionData[factionIndex]
    local harvest = false
    local salvage = false
    local filters = nil
    if fData then
        harvest = fData.harvest
        salvage = fData.salvage
        filters = fData.miningFilters
    end
    Player(playerIndex):invokeFunction("data/scripts/ForemanManager.lua", "sectorOperationsStatus_received", playerIndex, harvest, salvage, filters)
end
function PlayerOperations.factionOperationStarted(factionIndex, starterPlayerIndex, miningOperation, factionData)
    if factionData[factionIndex] then
        for _, player in pairs({Sector():getPlayers()}) do
            if player.index ~= starterPlayerIndex and player.allianceIndex == factionIndex then
                local starter = Player(starterPlayerIndex)
                if starter then
                    Player(player.index):sendChatMessage("Foreman", 3, (starter.name or "Unknown")..(miningOperation and " started mining operation"%_t or " started salvaging operation"%_t))
                    player:invokeFunction("data/scripts/ForemanManager.lua", "operationStarted", miningOperation)
                end
            end
        end
    end
end
function PlayerOperations.factionOperationStopped(factionIndex, stopperPlayerIndex, miningOperation, factionData)
    if factionData[factionIndex] then
        for _, player in pairs({Sector():getPlayers()}) do
            if player.index ~= stopperPlayerIndex and player.allianceIndex == factionIndex then
                local starter = Player(stopperPlayerIndex)
                if starter then
                    Player(player.index):sendChatMessage("Foreman", 3, (starter.name or "Unknown")..(miningOperation and " terminated mining operation"%_t or " terminated salvaging operation"%_t))
                end
                player:invokeFunction("data/scripts/ForemanManager.lua", "operationStopped", miningOperation)
            end
        end
    end
end
function PlayerOperations.getSectorOperationsStatus_server(callingPlayer)
    if callingPlayer ~= nil and Player(callingPlayer) and Player(callingPlayer).craft then
        Sector():invokeFunction("data/scripts/sector/ForemanSector.lua", "getOperationsStatus", callingPlayer, Player(callingPlayer).craft.factionIndex)
    end
end
function PlayerOperations.sectorOperationsStatus_received(playerIndex, harvestStatus, salvageStatus, inMiningFilters, harvest, salvage, miningFilters, filterCheckBoxes, startMiningButton, stopMiningButton, startSalvageButton, stopSalvageButton, recallFullShipsButton)
    harvest = harvestStatus
    salvage = salvageStatus
    if onServer() then
        if playerIndex ~= nil then
            local player = Player(playerIndex)
            if player then
                invokeClientFunction(player, "sectorOperationsStatus_received", nil, harvestStatus, salvageStatus, inMiningFilters)
            end
        end
    else
        if inMiningFilters ~= nil and #inMiningFilters > 0 and miningFilters and filterCheckBoxes then
            for i,v in pairs(inMiningFilters) do
                miningFilters[i] = v
                if filterCheckBoxes[i] then
                    filterCheckBoxes[i]:setCheckedNoCallback(v)
                end
            end
        else
            -- If no filter data received from server, initialize with default values (all materials allowed)
            if miningFilters and filterCheckBoxes then
                for materialIndex = 0, 6 do
                    if miningFilters[materialIndex] == nil then
                        miningFilters[materialIndex] = true
                        if filterCheckBoxes[materialIndex] then
                            filterCheckBoxes[materialIndex]:setCheckedNoCallback(true)
                        end
                    end
                end
            end
        end
        if startMiningButton then
            startMiningButton.active = not harvestStatus
        end
        if stopMiningButton then
            stopMiningButton.active = harvestStatus
        end
        if startSalvageButton then
            startSalvageButton.active = not salvageStatus
        end
        if stopSalvageButton then
            stopSalvageButton.active = salvageStatus
        end
        if recallFullShipsButton and not harvest and not salvage then
            recallFullShipsButton.active = false
        end
    end
    return harvest, salvage
end
function PlayerOperations.startMiningPressed(harvest, startMiningButton, stopMiningButton, autoDockPending, autoDockTimer, foremanMaterialLevel, scanAccuracy, miningFilters, getMineableAmountInVicinityCallback)
    harvest = true
    startMiningButton.active = false
    stopMiningButton.active = true
    if autoDockPending then
        autoDockPending = false
        autoDockTimer = 0
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-dock cancelled - mining resumed")
        end
    end
    if foremanMaterialLevel == nil and Player() and Player().craft then
        pcall(function()
            scanAccuracy, foremanMaterialLevel = ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(Player().craft.id, scanAccuracy, foremanMaterialLevel)
        end)
    end
    if foremanMaterialLevel == nil then
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Error, "No Foreman system found on this ship or unable to read mining level.")
        end
        harvest = false
        startMiningButton.active = true
        stopMiningButton.active = false
        return harvest, autoDockPending, autoDockTimer, foremanMaterialLevel, scanAccuracy
    end
    if getMineableAmountInVicinityCallback(true) == 0 then harvest = false end
    if onClient() then
        invokeServerFunction("launchMiningFighters", Player().craft.factionIndex, foremanMaterialLevel, miningFilters)
    end
    return harvest, autoDockPending, autoDockTimer, foremanMaterialLevel, scanAccuracy
end
function PlayerOperations.startSalvagingPressed(salvage, startSalvageButton, stopSalvageButton, yieldSalvageCountLabel, getSalvageTargetCountCallback, autoDockPending, autoDockTimer, foremanMaterialLevel, miningFilters)
    salvage = true
    startSalvageButton.active = false
    stopSalvageButton.active = true
    if yieldSalvageCountLabel then
        YieldUIManager.updateSalvageCount(getSalvageTargetCountCallback)
    end
    if autoDockPending then
        autoDockPending = false
        autoDockTimer = 0
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-dock cancelled - salvaging started")
        end
    end
    if onClient() then
        invokeServerFunction("launchSalvageFighters", Player().craft.factionIndex, foremanMaterialLevel, miningFilters)
    end
    return salvage, autoDockPending, autoDockTimer
end
function PlayerOperations.launchMiningFighters(factionIndex, foremanMaterial, inMiningFilters, harvest, callingPlayer)
    harvest = true
    Sector():addScriptOnce("data/scripts/sector/ForemanSector.lua")
    if onServer() and (foremanMaterial == nil) then
        local player = nil
        -- CRITICAL FIX: Don't fallback to random player
        if callingPlayer == nil then
            print("Foreman: ERROR - PlayerOperations function called without callingPlayer")
            return
        end
        
        player = Player(callingPlayer)
        if not player then
            print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
            return
        end
        if player and player.craft then
            local ok, level = pcall(function()
                return getHighestHarvestableMaterial(player.craft.id)
            end)
            if ok and level then
                foremanMaterial = level
            else
                print("Foreman: Failed to get highest harvestable material for ship " .. tostring(player.craft.id))
            end
        end
        if foremanMaterial == nil then foremanMaterial = 6 end
    end
    local x, y = Sector():getCoordinates()
    invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "startHarvesting", factionIndex, callingPlayer, foremanMaterial, inMiningFilters)
    return harvest
end
function PlayerOperations.launchSalvageFighters(factionIndex, foremanMaterial, inMiningFilters, salvage, callingPlayer)
    salvage = true
    Sector():addScriptOnce("data/scripts/sector/ForemanSector.lua")
    local x, y = Sector():getCoordinates()
    invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "startSalvaging", factionIndex, callingPlayer, foremanMaterial, inMiningFilters)
    return salvage
end
function PlayerOperations.operationStarted(miningOperation, harvest, startMiningButton, stopMiningButton, salvage, startSalvageButton, stopSalvageButton, getMineableAmountInVicinityCallback)
    if onServer() then
        invokeClientFunction(Player(), "operationStarted", miningOperation)
        return harvest, salvage
    end
    if miningOperation == true then
        harvest = true
        startMiningButton.active = false
        stopMiningButton.active = true
        if getMineableAmountInVicinityCallback(true) == 0 then harvest = false end
    else
        salvage = true
        startSalvageButton.active = false
        stopSalvageButton.active = true
    end
    return harvest, salvage
end
function PlayerOperations.operationStopped(miningOperation, harvest, startMiningButton, stopMiningButton, salvage, startSalvageButton, stopSalvageButton)
    if onServer() then
        invokeClientFunction(Player(), "operationStopped", miningOperation)
        return harvest, salvage
    end
    if miningOperation == true then
        harvest = false
        startMiningButton.active = true
        stopMiningButton.active = false
    else
        salvage = false
        startSalvageButton.active = true
        stopSalvageButton.active = false
    end
    return harvest, salvage
end
function PlayerOperations.stopMiningPressed(harvest, startMiningButton, stopMiningButton, autoDockPending, autoDockTimer, salvage, recallFullShipsButton)
    harvest = false
    startMiningButton.active = true
    stopMiningButton.active = false
    if autoDockPending then
        autoDockPending = false
        autoDockTimer = 0
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-dock cancelled - mining manually stopped")
        end
    end
    if not harvest and not salvage then
        recallFullShipsButton.active = false
    end
    if onClient() then
        invokeServerFunction("returnMiningSquads", Player().craft.factionIndex, Player().index)
    end
    return harvest, autoDockPending, autoDockTimer
end
function PlayerOperations.stopSalvagingPressed(salvage, startSalvageButton, stopSalvageButton, yieldSalvageCountLabel, getSalvageTargetCountCallback, autoDockPending, autoDockTimer, harvest, recallFullShipsButton)
    salvage = false
    startSalvageButton.active = true
    stopSalvageButton.active = false
    if yieldSalvageCountLabel then
        YieldUIManager.clearSalvageCount()
    end
    if autoDockPending then
        autoDockPending = false
        autoDockTimer = 0
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-dock cancelled - salvaging manually stopped")
        end
    end
    if not harvest and not salvage then
        recallFullShipsButton.active = false
    end
    if onClient() then
        invokeServerFunction("returnSalvageSquads", Player().craft.factionIndex, Player().index)
    end
    return salvage, autoDockPending, autoDockTimer
end
function PlayerOperations.returnMiningSquads(factionIndex, harvest, callingPlayer)
    harvest = false
    local x, y = Sector():getCoordinates()
    invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "returnMiningSquads", factionIndex, callingPlayer)
    return harvest
end
function PlayerOperations.returnSalvageSquads(factionIndex, salvage, callingPlayer)
    salvage = false
    local x, y = Sector():getCoordinates()
    invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "returnSalvageSquads", factionIndex, callingPlayer)
    return salvage
end
return PlayerOperations
