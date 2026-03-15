local llte_getDebugModules = getDebugModules
function getDebugModules(modTable)
    local dbgmodule = function(window)
        numButtons = 0
        local lltetab = window:createTab("", "data/textures/icons/cavaliers.png", "Long Live The Empress")

        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Test Name Generator", "onNameGeneratorButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Regenerate Weapons", "onRegenWeaponsButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Story Mission 1", "onLLTEStoryMission1ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Story Mission 2", "onLLTEStoryMission2ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Story Mission 3", "onLLTEStoryMission3ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Story Mission 4", "onLLTEStoryMission4ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Story Mission 5", "onLLTEStoryMission5ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Side Mission 1", "onLLTESideMission1ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Side Mission 2", "onLLTESideMission2ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Side Mission 3", "onLLTESideMission3ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Side Mission 4", "onLLTESideMission4ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Side Mission 5", "onLLTESideMission5ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Side Mission 6", "onLLTESideMission6ButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Give Cav Reinforcement Caller", "onCavReinforcementsCallerButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Cav Merchant", "onCavMerchantButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Get Excalibur", "onGetExcaliburButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Reset LLTE Vars", "onResetLLTEVarsButtonPressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Set Rep Level 1", "onLLTERep1Pressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Set Rep Level 3", "onLLTERep3Pressed")
        MakeButton(lltetab, ButtonRect(nil, nil, nil, lltetab.height), "Set Rep Level 5", "onLLTERep5Pressed")
    end

    table.insert(modTable, dbgmodule)

    return llte_getDebugModules(modTable)
end

_llte_campaign_script_values = {
    "_llte_cavaliers_ranklevel",
    "_llte_cavaliers_rank",
    "_llte_cavaliers_rep",
    "_llte_cavaliers_nextcontact",
    "_llte_cavaliers_startstory",
    "_llte_story_1_accomplished",
    "_llte_story_2_accomplished",
    "_llte_story_3_accomplished",
    "_llte_story_4_accomplished",
    "_llte_story_5_accomplished",
    "_llte_failedstory2",
    "_llte_pirate_faction_vengeance",
    "_llte_got_animosity_loot",
    "_llte_cavaliers_have_avorion",
    "_llte_cavaliers_strength",
    "_llte_cavaliers_inbarrier"
}

_llte_campaign_mission_scripts = {
    "missions/empress/story/lltestorymission1.lua",
    "missions/empress/story/lltestorymission2.lua",
    "missions/empress/story/lltestorymission3.lua",
    "missions/empress/story/lltestorymission4.lua",
    "missions/empress/story/lltestorymission5.lua",
    "missions/empress/side/lltesidemission1.lua",
    "missions/empress/side/lltesidemission2.lua",
    "missions/empress/side/lltesidemission3.lua",
    "missions/empress/side/lltesidemission4.lua",
    "missions/empress/side/lltesidemission5.lua",
    "missions/empress/side/lltesidemission6.lua"
}

function onNameGeneratorButtonPressed()
    LLTEUtil = include("llteutil")
    local _TestName = LLTEUtil.getRandomName(true, true)

    print("Test Name is " .. tostring(_TestName.name))
    print("Test Gender is " .. tostring(_TestName.gender))
end
callable(nil, "onNameGeneratorButtonPressed")

function onRegenWeaponsButtonPressed()
    if onClient() then
        invokeServerFunction("onRegenWeaponsButtonPressed")
        return
    end

    local _Cavs = Galaxy():findFaction("The Cavaliers")
    if not _Cavs then
        print("Haven't found The Cavaliers")
        return
    end
    _Cavs:setValue("_llte_cavaliers_regenArsenal", 1)
end
callable(nil, "onRegenWeaponsButtonPressed")

function onLLTEStoryMission1ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTEStoryMission1ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/empress/story/lltestorymission1.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTEStoryMission1ButtonPressed")

function onLLTEStoryMission2ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTEStoryMission2ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/empress/story/lltestorymission2.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTEStoryMission2ButtonPressed")

function onLLTEStoryMission3ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTEStoryMission3ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/empress/story/lltestorymission3.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTEStoryMission3ButtonPressed")

function onLLTEStoryMission4ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTEStoryMission4ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/empress/story/lltestorymission4.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTEStoryMission4ButtonPressed")

function onLLTEStoryMission5ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTEStoryMission5ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/empress/story/lltestorymission5.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTEStoryMission5ButtonPressed")

function onLLTESideMission1ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTESideMission1ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "data/scripts/player/missions/empress/side/lltesidemission1.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTESideMission1ButtonPressed")

function onLLTESideMission2ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTESideMission2ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "data/scripts/player/missions/empress/side/lltesidemission2.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTESideMission2ButtonPressed")

function onLLTESideMission3ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTESideMission3ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "data/scripts/player/missions/empress/side/lltesidemission3.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTESideMission3ButtonPressed")

function onLLTESideMission4ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTESideMission4ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "data/scripts/player/missions/empress/side/lltesidemission4.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTESideMission4ButtonPressed")

function onLLTESideMission5ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTESideMission5ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "data/scripts/player/missions/empress/side/lltesidemission5.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTESideMission5ButtonPressed")

function onLLTESideMission6ButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTESideMission6ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "data/scripts/player/missions/empress/side/lltesidemission6.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onLLTESideMission6ButtonPressed")

function onCavReinforcementsCallerButtonPressed()
    if onClient() then
        invokeServerFunction("onCavReinforcementsCallerButtonPressed")
        return
    end

    print("Adding Cavaliers reinforcement beacon")
    local _Player = Player(callingPlayer)
    local _AllyFaction = Galaxy():findFaction("The Cavaliers")

    _Player:getInventory():addOrDrop(
        UsableInventoryItem("cavaliersreinforcementtransmitter.lua", Rarity(RarityType.Exotic), _AllyFaction.index)
    )
end
callable(nil, "onCavReinforcementsCallerButtonPressed")

function onCavMerchantButtonPressed()
    if onClient() then
        invokeServerFunction("onCavMerchantButtonPressed")
        return
    end

    print("Spawning Cavaliers Merchant")
    local _Player = Player(callingPlayer)
    _Player:addScript("events/spawncavaliersmerchant.lua")
end
callable(nil, "onCavMerchantButtonPressed")

function onGetExcaliburButtonPressed()
    if onClient() then
        invokeServerFunction("onGetExcaliburButtonPressed")
        return
    end

    print("Getting EXCALIBUR railgun")

    LLTEUtil = include("llteutil")

    local _Player = Player(callingPlayer)
    _Player:getInventory():addOrDrop(LLTEUtil.getSpecialRailguns())
end
callable(nil, "onGetExcaliburButtonPressed")

function onResetLLTEVarsButtonPressed()
    if onClient() then
        invokeServerFunction("onResetLLTEVarsButtonPressed")
        return
    end

    print("Resetting LLTE Vars")

    local _player = Player(callingPlayer)

    for k, v in pairs(_llte_campaign_mission_scripts) do
        _player:removeScript(v)
    end

    for k, v in pairs(_llte_campaign_script_values) do
        _player:setValue(v, nil)
    end

    local _msg = "All Long Live The Empress data cleared."
    print(_msg)
    _player:sendChatMessage("Server", ChatMessageType.Information, _msg)
end
callable(nil, "onResetLLTEVarsButtonPressed")

function onLLTERep1Pressed()
    if onClient() then
        invokeServerFunction("onLLTERep1Pressed")
        return
    end

    print("Resetting Reputational LLTE Vars")

    local player = Player(callingPlayer)

    player:setValue("_llte_cavaliers_ranklevel", 1)
    player:setValue("_llte_cavaliers_rank", "Squire")
    player:setValue("_llte_cavaliers_rep", 4)
end
callable(nil, "onLLTERep1Pressed")

function onLLTERep3Pressed()
    if onClient() then
        invokeServerFunction("onLLTERep3Pressed")
        return
    end

    print("Resetting Reputational LLTE Vars")

    local player = Player(callingPlayer)

    player:setValue("_llte_cavaliers_ranklevel", 3)
    player:setValue("_llte_cavaliers_rank", "Crusader")
    player:setValue("_llte_cavaliers_rep", 29)
end
callable(nil, "onLLTERep3Pressed")

function onLLTERep5Pressed()
    if onClient() then
        invokeServerFunction("onLLTERep5Pressed")
        return
    end

    print("Resetting Reputational LLTE Vars")

    local player = Player(callingPlayer)

    player:setValue("_llte_cavaliers_ranklevel", 5)
    player:setValue("_llte_cavaliers_rank", "Paladin")
    player:setValue("_llte_cavaliers_rep", 51)
end
callable(nil, "onLLTERep5Pressed")

