local incthreat_getDebugModules = getDebugModules
function getDebugModules(modTable)
    local dbgmodule = function(window)
        numButtons = 0
        local incthreatTab = window:createTab("", "data/textures/icons/silicium.png", "Lord of the Wastes")

        MakeButton(incthreatTab, ButtonRect(nil, nil, nil, incthreatTab.height), "Pirate Attack", "onPirateAttackButtonPressed")
        MakeButton(incthreatTab, ButtonRect(nil, nil, nil, incthreatTab.height), "Decapitation Strike", "onDecapStrikeButtonPressed")
        MakeButton(incthreatTab, ButtonRect(nil, nil, nil, incthreatTab.height), "Deepfake Distress Call", "onDeepfakeDistressButtonPressed")
        MakeButton(incthreatTab, ButtonRect(nil, nil, nil, incthreatTab.height), "Fake Distress Call", "onFakeDistressButtonPressed")
    end

    table.insert(modTable, dbgmodule)

    return incthreat_getDebugModules(modTable)
end

function onPirateAttackButtonPressed()
    if onClient() then
        invokeServerFunction("onPirateAttackButtonPressed")
        return
    end

    Sector():addScript("pirateattack.lua")
end
callable(nil, "onPirateAttackButtonPressed")

function onDecapStrikeButtonPressed()
    if onClient() then
        invokeServerFunction("onDecapStrikeButtonPressed")
        return
    end

    Sector():addScript("decapstrike.lua")
end
callable(nil, "onDecapStrikeButtonPressed")

function onDeepfakeDistressButtonPressed()
    if onClient() then
        invokeServerFunction("onDeepfakeDistressButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:addScript("events/deepfakedistress.lua", true)
end
callable(nil, "onDeepfakeDistressButtonPressed")

function onFakeDistressButtonPressed()
    if onClient() then
        invokeServerFunction("onFakeDistressButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    _Player:addScript("events/itfakedistresssignal.lua", true)
end
callable(nil, "onFakeDistressButtonPressed")