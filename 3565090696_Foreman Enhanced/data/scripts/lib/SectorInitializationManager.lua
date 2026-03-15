include("callable")
ScanningManager = include("ScanningManager")
include("EntityQueryCache")
local SectorInitializationManager = {}
function SectorInitializationManager.initialize(scans, factionData)
    if onServer() then
        initializeEntityCache()
        ScanningManager.initialize(scans, factionData)
        math.randomseed(os.time())
        SectorInitializationManager.registerSectorCallbacks()
    end
end
function SectorInitializationManager.registerSectorCallbacks()
    if not _serverCallbacksRegistered then
        Sector():registerCallback("onSectorGenerated", "onSectorGenerated")
        Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
        Sector():registerCallback("onEntityEntered", "onEntityEntered")
        Sector():registerCallback("onEntityJump", "onEntityJump")
        Sector():registerCallback("onDestroyed", "onDestroyed")
        Sector():registerCallback("onSystemUpgradeLootCollected", "onSystemUpgradeLootCollected")
        Sector():registerCallback("onTurretLootCollected", "onTurretLootCollected")
        Sector():registerCallback("onSquadOrdersChanged", "onSquadOrdersChanged")
        Sector():registerCallback("onEntityCreated", "onEntityCreated")
        Sector():registerCallback("onEntityRemoved", "onEntityRemoved")
        _serverCallbacksRegistered = true
    end
end
return SectorInitializationManager
