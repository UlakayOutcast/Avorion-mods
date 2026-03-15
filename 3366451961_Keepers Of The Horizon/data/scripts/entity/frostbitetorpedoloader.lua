package.path = package.path .. ";data/scripts/lib/?.lua"
include ("utility")
include ("randomext")
include ("faction")
include ("sellableinventoryitem")
include ("callable")
local TorpedoUtility = include ("torpedoutility")
local TorpedoGenerator = include ("torpedogenerator")

ESCCUtil = include("esccutil")

local WarheadType = TorpedoUtility.WarheadType

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace FrostbiteTorpedoLoader
FrostbiteTorpedoLoader = {}
local self = FrostbiteTorpedoLoader

self.data = {}
self.torpedoes = {}

self._Debug = 0

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function FrostbiteTorpedoLoader.interactionPossible(playerIndex, option)
    local _MethodName = "Interaction Possible"
    self.Log(_MethodName, "Determining interactability with " .. tostring(playerIndex))
    local _Player = Player(playerIndex)
    local _Entity = Entity()

    local craft = _Player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(_Entity)
    local launcher = TorpedoLauncher(craft.index)

    --For once, we actually don't care about the player being a specific index.
    if dist < 300 and launcher then
        return true
    end

    return false
end

function FrostbiteTorpedoLoader.initialize(values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")

    self.data = values or {}

    if onServer() then
        --We actually don't care about any of this on the client.
        local torpGenerator = TorpedoGenerator()
        local _sector = Sector()
        local x, y = _sector:getCoordinates()

        local torpGenRarities = torpGenerator:getDefaultRarityDistribution()

        torpGenRarities[0] = 0 --no common torps. I'm okay with this being a little overpowered since you can't use it in the barrier.
        torpGenRarities[1] = torpGenRarities[1] * 0.75 --less of a chance of uncommon torps

        torpGenerator.rarities = torpGenRarities

        if not self.data.sabotOnly then
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Nuclear, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Neutron, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Fusion, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Tandem, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Kinetic, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Ion, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.Plasma, nil))
        end

        table.insert(self.torpedoes, torpGenerator:generate(x, x, nil, nil, WarheadType.Sabot, nil))

        if not self.data.sabotOnly then
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.EMP, nil))
            table.insert(self.torpedoes, torpGenerator:generate(x, y, nil, nil, WarheadType.AntiMatter, nil))
        end

        self.Log(_MethodName, "Torpedoes specially built.")
    end

    self.sync() --Have to sync for the initUI / onContactToLoad call.
end

function FrostbiteTorpedoLoader.initUI()
    ScriptUI():registerInteraction("Load Torpedoes", "onContactToLoad", 99)
end

function FrostbiteTorpedoLoader.onContactToLoad(_EntityIndex)
    local _MethodName = "On Contact to Load"
    self.Log(_MethodName, "Beginning... _EntityIndex is : " .. tostring(_EntityIndex))

    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    local d0 = {}

    --d0
    d0.text = "What type of Torpedoes do you want to load?"
    d0.answers = {}

    if not self.data.sabotOnly then
        table.insert(d0.answers, { answer = "[Nuclear]", onSelect = "OnLoadNuclearTorpedoes" })
        table.insert(d0.answers,{ answer = "[Neutron]", onSelect = "OnLoadNeutronTorpedoes" })
        table.insert(d0.answers,{ answer = "[Fusion]", onSelect = "OnLoadFusionTorpedoes" })
        table.insert(d0.answers,{ answer = "[Tandem]", onSelect = "OnLoadTandemTorpedoes" })
        table.insert(d0.answers,{ answer = "[Kinetic]", onSelect = "OnLoadKineticTorpedoes" })
        table.insert(d0.answers,{ answer = "[Ion]", onSelect = "OnLoadIonTorpedoes" })
        table.insert(d0.answers,{ answer = "[Plasma]", onSelect = "OnLoadPlasmaTorpedoes" })
    end

    table.insert(d0.answers, { answer = "[Sabot]", onSelect = "OnLoadSabotTorpedoes" })

    if not self.data.sabotOnly then
        table.insert(d0.answers, { answer = "[EMP]", onSelect = "OnLoadEMPTorpedoes" })
        table.insert(d0.answers, { answer = "[Antimatter]", onSelect = "OnLoadAntimatterTorpedoes" })
    end

    _UI:showDialog(d0)
end

--region #SERVER ONLY

function FrostbiteTorpedoLoader.loadSelectedTorpedoes(_PlayerID, _WarheadType)
    local _MethodName = "Load Selected Torpedoes"
    self.Log(_MethodName, "Beginning...")

    local _Torpedo
    for _, _T in pairs(self.torpedoes) do
        if _T.type == _WarheadType then
            self.Log(_MethodName, "Found appropriate torpedo type.")
            _Torpedo = _T
            break
        end
    end

    if not _Torpedo then
        self.Log(_MethodName, "Could not find torpedo. Exiting.")
        return
    end

    local _Player = Player(_PlayerID)
    local _Craft = _Player.craft
    local _Launcher = TorpedoLauncher(_Craft.index)
    local _Shafts = { _Launcher:getShafts() }
    local _TorpsLoaded = 0
    local _MaxTorpsToLoad = 330 --Enough to fill 10x avorion shafts + 100 in the torpedo bay.

    self.Log(_MethodName, "Adding torpedos directly to launchers.")

    for _, _Shaft in pairs(_Shafts) do
        local _attempts = 0 --Emergency breakout - per shaft. Sometimes placing a torpedo in a shaft just doesn't work and I have no idea why. There's no error or anything.
        local initialFreeSlots = _Launcher:getFreeSlots(_Shaft) --For some reason the game will register nonexistent shafts as having 15 free slots. It's fucking wack.
        while _Launcher:getFreeSlots(_Shaft) > 0 and initialFreeSlots ~= 15 and _attempts < 100 and _TorpsLoaded < _MaxTorpsToLoad do
            local _freeSlots1 = _Launcher:getFreeSlots(_Shaft)
            _Launcher:addTorpedo(_Torpedo, _Shaft)

            local _freeSlots2 = _Launcher:getFreeSlots(_Shaft)
            if _freeSlots2 < _freeSlots1 then
                _TorpsLoaded = _TorpsLoaded + 1
            end

            _attempts = _attempts + 1
        end
    end

    self.Log(_MethodName, "Adding torpeodes to storage.")

    local _storageattempts = 0 --Second emergency breakout
    while _Launcher.freeStorage > _Torpedo.size and _storageattempts < 1000 and _TorpsLoaded < _MaxTorpsToLoad do
        local _freeStorage1 = _Launcher.freeStorage
        _Launcher:addTorpedo(_Torpedo)

        local _freeStorage2 = _Launcher.freeStorage
        if _freeStorage2 < _freeStorage1 then
            _TorpsLoaded = _TorpsLoaded + 1
        end

        _storageattempts = _storageattempts + 1
    end

    local _Ship = Entity()
    Sector():broadcastChatMessage(_Ship, ChatMessageType.Chatter, "Rearming complete! You're good to go, Captain!")
    local _Rgen = ESCCUtil.getRand()
    _Ship:addScript("entity/utility/delayeddelete.lua", _Rgen:getFloat(2, 4))
end
callable(FrostbiteTorpedoLoader, "loadSelectedTorpedoes")

--endregion

--region #LOAD TORPEDO TYPES -- these are CLIENT ONLY calls. We need to tell the server what kind of torpedoes to load.

function FrostbiteTorpedoLoader.OnLoadNuclearTorpedoes()
    local _MethodName = "On Load Nuclear Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Nuclear)
end

function FrostbiteTorpedoLoader.OnLoadNeutronTorpedoes()
    local _MethodName = "On Load Neutron Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Neutron)
end

function FrostbiteTorpedoLoader.OnLoadFusionTorpedoes()
    local _MethodName = "On Load Fusion Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Fusion)
end

function FrostbiteTorpedoLoader.OnLoadTandemTorpedoes()
    local _MethodName = "On Load Tandem Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Tandem)
end

function FrostbiteTorpedoLoader.OnLoadKineticTorpedoes()
    local _MethodName = "On Load Kinetic Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Kinetic)
end

function FrostbiteTorpedoLoader.OnLoadIonTorpedoes()
    local _MethodName = "On Load Ion Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Ion)
end

function FrostbiteTorpedoLoader.OnLoadPlasmaTorpedoes()
    local _MethodName = "On Load Plasma Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Plasma)
end

function FrostbiteTorpedoLoader.OnLoadSabotTorpedoes()
    local _MethodName = "On Load Sabot Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.Sabot)
end

function FrostbiteTorpedoLoader.OnLoadEMPTorpedoes()
    local _MethodName = "On Load EMP Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.EMP)
end

function FrostbiteTorpedoLoader.OnLoadAntimatterTorpedoes()
    local _MethodName = "On Load Antimatter Torpedoes"
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index, WarheadType.AntiMatter)
end

--endregion

--region #CLIENT / SERVER CALLS

function FrostbiteTorpedoLoader.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Frostbite Torpedo Loader] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

function FrostbiteTorpedoLoader.sync(dataIn)
    if onServer() then
        broadcastInvokeClientFunction("sync", self.data)
    else
        if dataIn then
            self.data = dataIn
        else
            invokeServerFunction("sync")
        end
    end
end
callable(FrostbiteTorpedoLoader, "sync")

--endregion