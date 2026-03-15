local CallbackRegistrationManager = {}

function CallbackRegistrationManager.registerSectorCallbacks(callbacksRegistered)
    if callbacksRegistered then return end
    
    Sector():registerCallback("onEntityCreated", "onEntityCreated_client")
    Sector():registerCallback("onEntityRemoved", "onEntityRemoved_client")
    Sector():registerCallback("onCraftSeatEntered", "onCraftSeatEntered_client")
    Sector():registerCallback("onCraftSeatLeft", "onCraftSeatLeft_client")
    Sector():registerCallback("onSystemsChanged", "onSystemsChanged")
    Sector():registerCallback("onCrewChanged", "onCrewChanged")
    Sector():registerCallback("onFighterAdded", "onFighterAdded")
    Sector():registerCallback("onFighterRemoved", "onFighterRemoved")
    Sector():registerCallback("onSquadAdded", "onSquadAdded")
    Sector():registerCallback("onSquadRemoved", "onSquadRemoved")
    callbacksRegistered = true
end

return CallbackRegistrationManager
