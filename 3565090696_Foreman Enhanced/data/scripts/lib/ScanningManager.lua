include("callable")
local ScanningManager = {}

-- Debug flag - set to true to enable debug output
local DEBUG_SCANNING = false

-- Debug print function
local function debugPrint(...)
    if DEBUG_SCANNING then
        print("ScanningManager:", ...)
    end
end
local scans = nil
local factionData = nil
local scanNumber = 0

function ScanningManager.initialize(scansRef, factionDataRef)
    scans = scansRef
    factionData = factionDataRef
    scanNumber = 0
end

function ScanningManager.updateScanningStatuses(timeStep)
    if not scans then return end
    
    for factionIndex, status in pairs(scans) do
        if status.sectorScanTimeLeft > 0 then
            status.sectorScanTimeLeft = status.sectorScanTimeLeft - timeStep
            if status.sectorScanTimeLeft <= 0 then
                ScanningManager.scanComplete(factionIndex, status.scanNumber)
            end
        end
    end
end
function ScanningManager.startScanningServer(factionIndex, starterPlayerIndex, scanningTime, shipIndex)
    if not scans or not factionData then
        debugPrint("Not initialized properly")
        return
    end
    scans[factionIndex] = {}
    scans[factionIndex].scanNumber = scanNumber
    scans[factionIndex].sectorScanTime = scanningTime
    scans[factionIndex].sectorScanTimeLeft = scanningTime
    scans[factionIndex].sectorScanStarter = tostring(shipIndex)
    for _, player in pairs({Sector():getPlayers()}) do
        if player.index == factionIndex or player.allianceIndex == factionIndex then
            if player.allianceIndex ~= nil and player.index ~= starterPlayerIndex then
                local starter = Player(starterPlayerIndex)
                if starter then
                    Player(player.index):sendChatMessage("Foreman", 3, (starter.name or "Unknown").." started scanning"%_t)
                end
            end
            player:invokeFunction("data/scripts/ForemanManager.lua", "scanStarted", scanningTime)
        end
    end
    deferredCallback(scanningTime, "scanComplete", factionIndex, scanNumber)
    scanNumber = scanNumber + 1
end
function ScanningManager.scanCancelled(factionIndex)
    if not scans or not factionData then
        debugPrint("Not initialized properly")
        return
    end
    if scans[factionIndex] == nil then return end
    for _, player in pairs({Sector():getPlayers()}) do
        if player.index == factionIndex or player.allianceIndex == factionIndex then
            Player(player.index):sendChatMessage("Foreman", 3, "Scan cancelled"%_t)
            player:invokeFunction("data/scripts/ForemanManager.lua", "scanCancelled")
        end
    end
    scans[factionIndex] = nil
end
function ScanningManager.scanComplete(factionIndex, scanNum)
    if not scans or not factionData then
        debugPrint("Not initialized properly")
        return
    end
    if scans[factionIndex] and scans[factionIndex].scanNumber == scanNum then
        if factionData[factionIndex] then
            factionData[factionIndex].sectorScanned = true
            debugPrint("Scan complete for faction", factionIndex, "calling sectorScanComplete")
            for _, player in pairs({Sector():getPlayers()}) do
                if player.index == factionIndex or player.allianceIndex == factionIndex then
                    debugPrint("Invoking sectorScanComplete for player", player.index)
                    player:invokeFunction("data/scripts/ForemanManager.lua", "sectorScanComplete")
                end
            end
        end
        scans[factionIndex] = nil
    end
end
function ScanningManager.getScanStatus(factionIndex, playerIndex)
    if not scans or not factionData then
        debugPrint("Not initialized properly")
        return
    end
    local scan = scans[factionIndex]
    if scan then
        Player(playerIndex):invokeFunction("data/scripts/ForemanManager.lua", "receiveScanStatus", scan.sectorScanTime, scan.sectorScanTimeLeft)
    else
        if factionData[factionIndex] and factionData[factionIndex].sectorScanned then
            Player(playerIndex):invokeFunction("data/scripts/ForemanManager.lua", "sectorScanComplete")
        end
    end
end
function ScanningManager.hasActiveScan(factionIndex)
    if not scans then
        return false
    end
    return scans[factionIndex] ~= nil
end
function ScanningManager.getScanData(factionIndex)
    if not scans then
        return nil
    end
    return scans[factionIndex]
end
function ScanningManager.scanButtonPressed()
    ScanningManager.startScanning()
end
function ScanningManager.startScanning(factionIndex, scanTime, shipIndex)
    if onClient() then
        local entity = Player().craft
        local time
        for upgrade, permanent in pairs(ShipSystem(entity.id):getUpgrades()) do
            if upgrade.script == "data/scripts/systems/foremansystem.lua" then
                local ret,_, _, _, _, _, sectorScanningSpeed, _ = entity:invokeFunction("data/scripts/systems/foremansystem.lua", "getBonuses", upgrade.seed.int32, upgrade.rarity, permanent)
                time = sectorScanningSpeed
            end
        end
        if not time or time <= 0 then
            time = 8 -- fallback scan time if bonuses not yet available
        end
        factionIndex = Player().craft.factionIndex
        invokeServerFunction("startScanning", factionIndex, time, entity.index)
    else
        local x, y = Sector():getCoordinates()
        invokeSectorFunction(x, y, nil, "data/scripts/sector/ForemanSector.lua", "startScanning", factionIndex, callingPlayer, scanTime, shipIndex)
    end
end
callable(ScanningManager, "startScanning")
function ScanningManager.scanStarted(scanTime)
    if onServer() then
        invokeClientFunction(Player(), "scanStarted", scanTime)
    else
        return scanTime
    end
end
callable(ScanningManager, "scanStarted")
function ScanningManager.cancelScan()
    return true
end
function ScanningManager.getSectorScanStatus(factionIndex)
    if onClient() then
        invokeServerFunction("getSectorScanStatus", Player().craft.factionIndex)
        invokeServerFunction("getSectorOperationsStatus_server")
    else
        local x, y = Sector():getCoordinates()
        invokeSectorFunction(x, y, nil, "data/scripts/sector/ForemanSector.lua", "getScanStatus", factionIndex, callingPlayer)
    end
end
callable(ScanningManager, "getSectorScanStatus")
function ScanningManager.receiveScanStatus(scanTime, timeLeft)
    if onServer() then
        invokeClientFunction(Player(), "receiveScanStatus", scanTime, timeLeft)
    else
        return scanTime, timeLeft
    end
end
callable(ScanningManager, "receiveScanStatus")
callable(ScanningManager, "scanCancelled")
callable(ScanningManager, "scanComplete")
return ScanningManager
