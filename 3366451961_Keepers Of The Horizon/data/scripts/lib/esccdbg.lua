local HorizonUtil = include("horizonutil")

local koth_getDebugModules = getDebugModules
function getDebugModules(modTable)
    --0x6573636320646267206370676E7461622066756E63205354415254
    local koth_dbgmodule = function(window)
        numButtons = 0
        local HKTab = window:createTab("", "data/textures/icons/snowflake-2.png", "Horizon Keepers")

        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 1", "onHKTabMission1ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 2", "onHKTabMission2ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 3", "onHKTabMission3ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 4", "onHKTabMission4ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 5", "onHKTabMission5ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 6", "onHKTabMission6ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 7", "onHKTabMission7ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 8", "onHKTabMission8ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Mission 9", "onHKTabMission9ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Side Mission 1", "onHKTabSideMission1ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Side Mission 2", "onHKTabSideMission2ButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Frostbite Torp Loader", "onSpawnFrostbiteTorpLoaderButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Frostbite AWACS", "onSpawnFrostibteAWACSButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Frostbite Warship", "onSpawnFrostbiteWarshipButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Frostbite Relief", "onSpawnFrostbiteReliefButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Varlance", "onSpawnVarlanceButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Ice Nova", "onSpawnIceNovaButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK Freighter", "onSpawnHKFreightButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK Artillery Cruiser", "onSpawnHKACruiseButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK Combat Cruiser", "onSpawnHKCCruiseButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK AWACS", "onSpawnHKAWACSButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK Battleship", "onSpawnHKBshipButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK Hansel", "onSpawnHKHanselButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn HK Gretel", "onSpawnHKGretelButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn XSOLOGIZE", "onSpawnXsologizeButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Horizon Shipyard 1", "onHKShipyard1Pressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Horizon Shipyard 2", "onHKShipyard2Pressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Spawn Horizon Research 1", "onHKResearchPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Give Frostbite Torpedo Loader Beacon", "onFBTorpedoLoaderBeaconPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Give Story 8 Items", "onGiveStory8ItemsButtonPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Reset Cooldowns", "onResetFBCooldownsPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Unlock Encyclopedia", "onUnlockAllKOTHEncyclopediaPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Dump Values", "onHKDumpValuesPressed")
        MakeButton(HKTab, ButtonRect(nil, nil, nil, HKTab.height), "Clear Values", "onHKClearValuesPressed")
    end
    --0x6573636320646267206370676E7461622066756E6320454E44

    --0x6573636320646267206370676E7461622074626C20696E73
    table.insert(modTable, koth_dbgmodule)

    return koth_getDebugModules(modTable)
end

--0x657363632064656275672074616220726567696F6E205354415254
--region #KOTH tab

--Pick an alias that's unlikely to be taken
_horizonkeepers_campaign_script_values = {
    "_horizonkeepers_story_stage",
    "_horizonkeepers_story_complete",
    "_horizonkeepers_story3_cargolooted",
    "_horizonkeepers_killed_hansel",
    "_horizonkeepers_killed_gretel",
    "_horizonkeepers_story7_heardplan",
    "_horizonkeepers_last_side1",
    "_horizonkeepers_last_side2",
    "_horizonkeepers_side1_complete",
    "_horizonkeepers_side2_complete",
    "encyclopedia_koth_frostbite",
    "encyclopedia_koth_varlance",
    "encyclopedia_koth_horizonkeepers",
    "encyclopedia_koth_sophie",
    "encyclopedia_koth_hanselgretel",
    "encyclopedia_koth_torploader",
    "encyclopedia_koth_xsologize",
    "encyclopedia_koth_01macedon"
}

_horizonkeepers_campaign_mission_scripts = {
    "missions/horizon/horizonstory1.lua",
    "missions/horizon/horizonstory2.lua",
    "missions/horizon/horizonstory3.lua",
    "missions/horizon/horizonstory4.lua",
    "missions/horizon/horizonstory5.lua",
    "missions/horizon/horizonstory6.lua",
    "missions/horizon/horizonstory7.lua",
    "missions/horizon/horizonstory8.lua",
    "missions/horizon/horizonstory9.lua",
    "missions/horizon/horizonside1.lua",
    "missions/horizon/horizonside2.lua"
}

function onHKTabMission1ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission1ButtonPressed")
        return
    end

    local _station = Entity()
    if _station.type ~= EntityType.Station then
        print("Can't add missions to non-station entities.")
    else
        if _station.playerOrAllianceOwned then
            print("Can't add missions to player or alliance stations.")
        else
            print("Adding Horizon 1 bulletin.")
            local _MissionPath = "data/scripts/player/missions/horizon/horizonstory1.lua"
            local ok, bulletin=run(_MissionPath, "getBulletin", _station)
            _station:invokeFunction("bulletinboard", "postBulletin", bulletin)
        end
    end
end
callable(nil, "onHKTabMission1ButtonPressed")

function onHKTabMission2ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission2ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory2.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission2ButtonPressed")

function onHKTabMission3ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission3ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory3.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission3ButtonPressed")

function onHKTabMission4ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission4ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory4.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission4ButtonPressed")

function onHKTabMission5ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission5ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory5.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission5ButtonPressed")

function onHKTabMission6ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission6ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory6.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission6ButtonPressed")

function onHKTabMission7ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission7ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory7.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission7ButtonPressed")

function onHKTabMission8ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission8ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory8.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission8ButtonPressed")

function onHKTabMission9ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabMission9ButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _Script = "missions/horizon/horizonstory9.lua"
    _Player:removeScript(_Script)
    _Player:addScript(_Script)
end
callable(nil, "onHKTabMission9ButtonPressed")

function onHKTabSideMission1ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabSideMission1ButtonPressed")
        return
    end

    local _station = Entity()
    if _station.type ~= EntityType.Station then
        print("Can't add missions to non-station entities.")
    else
        if _station.playerOrAllianceOwned then
            print("Can't add missions to player or alliance stations.")
        else
            print("Adding Horizon Side 1 bulletin.")
            local _MissionPath = "data/scripts/player/missions/horizon/horizonside1.lua"
            local ok, bulletin= run(_MissionPath, "getBulletin", _station)
            _station:invokeFunction("bulletinboard", "postBulletin", bulletin)
        end
    end    
end
callable(nil, "onHKTabSideMission1ButtonPressed")

function onHKTabSideMission2ButtonPressed()
    if onClient() then
        invokeServerFunction("onHKTabSideMission2ButtonPressed")
        return
    end

    local _station = Entity()
    if _station.type ~= EntityType.Station then
        print("Can't add missions to non-station entities.")
    else
        if _station.playerOrAllianceOwned then
            print("Can't add missions to player or alliance stations.")
        else
            print("Adding Horizon Side 2 bulletin.")
            local _MissionPath = "data/scripts/player/missions/horizon/horizonside2.lua"
            local ok, bulletin= run(_MissionPath, "getBulletin", _station)
            _station:invokeFunction("bulletinboard", "postBulletin", bulletin)
        end
    end    
end
callable(nil, "onHKTabSideMission2ButtonPressed")

local torpLoaderSpawns = 0
function onSpawnFrostbiteTorpLoaderButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFrostbiteTorpLoaderButtonPressed")
        return
    end

    local sabotOnly = true
    if math.fmod(torpLoaderSpawns, 2) == 1 then
        print("Spawn " .. tostring(torpLoaderSpawns) .. " - setting sabot only to false")
        sabotOnly = false
    end

    HorizonUtil.spawnFrostbiteTorpedoLoader(false, sabotOnly)

    torpLoaderSpawns = torpLoaderSpawns + 1
end
callable(nil, "onSpawnFrostbiteTorpLoaderButtonPressed")

function onSpawnFrostibteAWACSButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFrostibteAWACSButtonPressed")
        return
    end

    HorizonUtil.spawnFrostbiteAWACS(false)
end
callable(nil, "onSpawnFrostibteAWACSButtonPressed")

function onSpawnFrostbiteWarshipButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFrostbiteWarshipButtonPressed")
        return
    end

    HorizonUtil.spawnFrostbiteWarship(false)
end
callable(nil, "onSpawnFrostbiteWarshipButtonPressed")

function onSpawnFrostbiteReliefButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFrostbiteReliefButtonPressed")
        return
    end

    HorizonUtil.spawnFrostbiteReliefShip(false)
end
callable(nil, "onSpawnFrostbiteReliefButtonPressed")

function onSpawnVarlanceButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnVarlanceButtonPressed")
        return
    end

    HorizonUtil.spawnVarlanceNormal(false)
end
callable(nil, "onSpawnVarlanceButtonPressed")

function onSpawnIceNovaButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnIceNovaButtonPressed")
        return
    end

    HorizonUtil.spawnVarlanceBattleship(false)
end
callable(nil, "onSpawnIceNovaButtonPressed")

function onSpawnHKFreightButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKFreightButtonPressed")
        return
    end

    HorizonUtil.spawnHorizonFreighter(false, nil, nil)
end
callable(nil, "onSpawnHKFreightButtonPressed")

function onSpawnHKACruiseButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKACruiseButtonPressed")
        return
    end

    HorizonUtil.spawnHorizonArtyCruiser(false, nil, nil)
end
callable(nil, "onSpawnHKACruiseButtonPressed")

function onSpawnHKCCruiseButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKCCruiseButtonPressed")
        return
    end

    HorizonUtil.spawnHorizonCombatCruiser(false, nil, nil)
end
callable(nil, "onSpawnHKCCruiseButtonPressed")

function onSpawnHKAWACSButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKAWACSButtonPressed")
        return
    end

    HorizonUtil.spawnHorizonAWACS(false, nil, nil)
end
callable(nil, "onSpawnHKAWACSButtonPressed")

function onSpawnHKBshipButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKBshipButtonPressed")
        return
    end

    HorizonUtil.spawnHorizonBattleship(false, nil, nil)
end
callable(nil, "onSpawnHKBshipButtonPressed")

function onSpawnHKHanselButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKHanselButtonPressed")
        return
    end

    HorizonUtil.spawnAlphaHansel(false, nil, false)
end
callable(nil, "onSpawnHKHanselButtonPressed")

function onSpawnHKGretelButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnHKGretelButtonPressed")
        return
    end

    HorizonUtil.spawnBetaGretel(false, nil, false)
end
callable(nil, "onSpawnHKGretelButtonPressed")

function onSpawnXsologizeButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsologizeButtonPressed")
        return
    end

    HorizonUtil.spawnProjectXsologize(false, nil)
end
callable(nil, "onSpawnXsologizeButtonPressed")

function onHKShipyard1Pressed()
    if onClient() then
        invokeServerFunction("onHKShipyard1Pressed")
        return
    end

    HorizonUtil.spawnHorizonShipyard1(false, nil)
end
callable(nil, "onHKShipyard1Pressed")

function onHKShipyard2Pressed()
    if onClient() then
        invokeServerFunction("onHKShipyard2Pressed")
        return
    end

    HorizonUtil.spawnHorizonShipyard2(false, nil)
end
callable(nil, "onHKShipyard2Pressed")

function onHKResearchPressed()
    if onClient() then
        invokeServerFunction("onHKResearchPressed")
        return
    end

    HorizonUtil.spawnHorizonResearchStation(false, nil)
end
callable(nil, "onHKResearchPressed")

function onFBTorpedoLoaderBeaconPressed()
    if onClient() then
        invokeServerFunction("onFBTorpedoLoaderBeaconPressed")
        return
    end

    print("Adding Frostbite torpedo loader beacon")
    local _Player = Player(callingPlayer)
    local friendlyFaction = HorizonUtil.getFriendlyFaction()

    _Player:getInventory():addOrDrop(
        UsableInventoryItem("frostbitetorpedoloadercaller.lua", Rarity(RarityType.Legendary), friendlyFaction.index)
    )
end
callable(nil, "onFBTorpedoLoaderBeaconPressed")

function onGiveStory8ItemsButtonPressed()
    if onClient() then
        invokeServerFunction("onGiveStory8ItemsButtonPressed")
        return
    end

    local goodsTable = {
        { itemName = "Energy Cell", itemAmount = 5 },
        { itemName = "Computation Mainframe", itemAmount = 1 },
        { itemName = "Coolant", itemAmount = 1 },
        { itemName = "Satellite", itemAmount = 1 },
        { itemName = "Food Bar", itemAmount = 3 }
    }

    local entity = Player(callingPlayer).craft

    print("adding items needed for story mission 8")

    for idx, item in pairs(goodsTable) do
        local _Good = item.itemName
        local _GoodsToAdd = item.itemAmount

        CargoBay(entity):addCargo(goods[_Good]:good(), _GoodsToAdd)
    end

end
callable(nil, "onGiveStory8ItemsButtonPressed")

function onResetFBCooldownsPressed()
    if onClient() then
        invokeServerFunction("onResetFBCooldownsPressed")
        return
    end

    print("Resetting Horizon Keepers Cooldowns")
    local _player = Player(callingPlayer)
    local friendlyFaction = HorizonUtil.getFriendlyFaction()

    _player:setValue("torploader_requested_" .. friendlyFaction.index, 0)
    _player:setValue("_horizonkeepers_last_side1", 0)
    _player:setValue("_horizonkeepers_last_side2", 0)
end
callable(nil, "onResetFBCooldownsPressed")

function onUnlockAllKOTHEncyclopediaPressed()
    if onClient() then
        invokeServerFunction("onUnlockAllKOTHEncyclopediaPressed")
        return
    end

    print("Unlocking Horizon Keeper Encyclopedia entries")

    local _player = Player(callingPlayer)
    _player:setValue("encyclopedia_koth_frostbite", true)
    _player:setValue("encyclopedia_koth_varlance", true)
    _player:setValue("encyclopedia_koth_horizonkeepers", true)
    _player:setValue("encyclopedia_koth_sophie", true)
    _player:setValue("encyclopedia_koth_hanselgretel", true)
    _player:setValue("encyclopedia_koth_torploader", true)
    _player:setValue("encyclopedia_koth_xsologize", true)
    _player:setValue("encyclopedia_koth_01macedon", true)
end
callable(nil, "onUnlockAllKOTHEncyclopediaPressed")

function onHKDumpValuesPressed()
    if onClient() then
        invokeServerFunction("onHKDumpValuesPressed")
        return
    end

    local _player = Player(callingPlayer)
    for k, v in pairs(_horizonkeepers_campaign_script_values) do
        print("Name : " .. tostring(v) .. " // Value : " .. tostring(_player:getValue(v)))
    end
end
callable(nil, "onHKDumpValuesPressed")

function onHKClearValuesPressed()
    if onClient() then
        invokeServerFunction("onHKClearValuesPressed")
        return
    end

    local _player = Player(callingPlayer)

    for k, v in pairs(_horizonkeepers_campaign_mission_scripts) do
        _player:removeScript(v)
    end

    for k, v in pairs(_horizonkeepers_campaign_script_values) do
        _player:setValue(v, nil)
    end
    _player:setValue("_horizonkeepers_story_stage", 1) --Have to reset this one indiviudally b/c the loop nils them all out.
   
    HorizonUtil.setFriendlyFactionRep(_player, 0)

    local _msg = "All Horizon Keepers data cleared."
    print(_msg)
    _player:sendChatMessage("Server", ChatMessageType.Information, _msg)
end
callable(nil, "onHKClearValuesPressed")

--endregion
--0x657363632064656275672074616220726567696F6E20454E44