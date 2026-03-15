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
-- namespace CavaliersTorpedoLoader
CavaliersTorpedoLoader = {}
local self = CavaliersTorpedoLoader

self._Torpedoes = {}

self._Debug = 0

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function CavaliersTorpedoLoader.interactionPossible(playerIndex, option)
    local _Player = Player(playerIndex)
    local _Rank = _Player:getValue("_llte_cavaliers_ranklevel")
    local _Entity = Entity()
    local _CanInteract = true
    if _Rank and _Rank >= 2 then
        --Do nothing
    else
        _CanInteract = false
    end

    local craft = _Player.craft
    if not craft then
        _CanInteract = false
    end

    local dist = craft:getNearestDistance(_Entity)
    if dist > 300 then
        _CanInteract = false
    end

    local _Launcher = TorpedoLauncher(craft.index)
    if not _Launcher then
        _CanInteract = false
    end

    return _CanInteract
end

function CavaliersTorpedoLoader.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")

    if onServer() then
        --We actually don't care about any of this on the client.
        local _TorpGenerator = TorpedoGenerator()
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()

        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Nuclear, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Neutron, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Fusion, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Tandem, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Kinetic, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Ion, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Plasma, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.Sabot, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.EMP, nil))
        table.insert(self._Torpedoes, _TorpGenerator:generate(_X, _Y, nil, nil, WarheadType.AntiMatter, nil))

        self.Log(_MethodName, "Torpedoes specially built.")
    end
end

function CavaliersTorpedoLoader.initUI()
    ScriptUI():registerInteraction("Load Torpedoes"%_t, "onContactToLoad", 99)
end

function CavaliersTorpedoLoader.onContactToLoad(_EntityIndex)
    local _MethodName = "On Contact to Load"
    self.Log(_MethodName, "Beginning... _EntityIndex is : " .. tostring(_EntityIndex))

    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    local d0 = {}

    --d0
    d0.text = "Какой тип торпед вы хотите загрузить?"
    d0.answers = {
        { answer = "[Nuclear]", onSelect = "OnLoadNuclearTorpedoes" },
        { answer = "[Neutron]", onSelect = "OnLoadNeutronTorpedoes" },
        { answer = "[Fusion]", onSelect = "OnLoadFusionTorpedoes" },
        { answer = "[Tandem]", onSelect = "OnLoadTandemTorpedoes" },
        { answer = "[Kinetic]", onSelect = "OnLoadKineticTorpedoes" },
        { answer = "[Ion]", onSelect = "OnLoadIonTorpedoes" },
        { answer = "[Plasma]", onSelect = "OnLoadPlasmaTorpedoes" },
        { answer = "[Sabot]", onSelect = "OnLoadSabotTorpedoes" },
        { answer = "[EMP]", onSelect = "OnLoadEMPTorpedoes" },
        { answer = "[Antimatter]", onSelect = "OnLoadAntimatterTorpedoes" }
    }

    _UI:showDialog(d0)
end

function CavaliersTorpedoLoader.onConfirmToLoad(_EntityIndex, _Qty, _Cost, _Type)
    local _MethodName = "On Contact to Confirm Load"
    self.Log(_MethodName, "Beginning... _EntityIndex is : " .. tostring(_EntityIndex))

    local _UI = ScriptUI(_EntityIndex)
    if not _UI then 
        return 
    end

    local _Player = Player()

    local d0 = {}

    if _Player:canPay(_Cost) then
        self.Log(_MethodName, "Player can pay.")
        d0.text = "Это будет стоить " .. tostring(_Cost) .. ", чтобы загрузить " .. tostring(_Qty) .. ", " .. self.getStringForType(_Type) .. " торпеды. Хотите продолжить?"
        d0.answers = {
            { answer = "Да.", onSelect = "OnLoadTorpedoesConfirmed" },
            { answer = "Нет." }
        }
    else
        self.Log(_MethodName, "Player can't pay.")
        d0.text = "У вас недостаточно денег, чтобы загрузить этот тип торпеды!"
    end

    self.Log(_MethodName, "Showing dialog - d0.text is : " .. tostring(d0.text))

    _UI:interactShowDialog(d0)
end

--region #SERVER ONLY

--Calculate the cost of loading the torpedoes.
function CavaliersTorpedoLoader.CalculateTorpedoPrice(_PlayerID, _WarheadType)
    local _MethodName = "Calculate Torpedo Price"
    self._TorpedoType = _WarheadType

    local _Cost = 0
    local _Qty = 0
    local _Size = 0

    local _TotalPrice = 0
    for _, _T in pairs(self._Torpedoes) do
        if _T.type == _WarheadType then
            _Cost = TorpedoPrice(_T)
            _Size = _T.size
            break
        end
    end

    if _Cost == 0 or _Size == 0 then
        self.Log(_MethodName, "Could not find a torpedo.")
        return
    end

    self.Log(_MethodName, "Price of indivudal torpedo is " .. _Cost)
    --Calculate how much free space is available.
    local _Player = Player(_PlayerID)
    local _Craft = _Player.craft
    local _Launcher = TorpedoLauncher(_Craft.index)
    local _Shafts = {_Launcher:getShafts()}
    for _, _Shaft in pairs(_Shafts) do
        --For some reason 15 means that the shaft is unavailble due to the player not building a launcher block.
        if _Launcher:getFreeSlots(_Shaft) ~= 15 then
            _Qty = _Qty + _Launcher:getFreeSlots(_Shaft)
        end
    end

    local _Extra = math.floor(_Launcher.freeStorage / _Size)
    _Qty = _Qty + _Extra
    
    self.Log(_MethodName, "Your ship can hold " .. tostring(_Qty) .. " torpedoes.")

    local _Total = (_Cost * _Qty) * 0.5
    self._TotalPrice = _Total

    self.Log(_MethodName, "Your ship will cost " .. tostring(_Total) .. " to load. Invoking onConfirmToLoad for player " .. tostring(_Player.name) .. ".")

    invokeClientFunction(_Player, "onConfirmToLoad", Entity().index, _Qty, _Total, _WarheadType)
end
callable(CavaliersTorpedoLoader, "CalculateTorpedoPrice")

function CavaliersTorpedoLoader.loadSelectedTorpedoes(_PlayerID)
    local _MethodName = "Load Selected Torpedoes"
    self.Log(_MethodName, "Beginning...")

    local _Torpedo
    for _, _T in pairs(self._Torpedoes) do
        if _T.type == self._TorpedoType then
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
    _Player:pay(self._TotalPrice)
    local _Craft = _Player.craft
    local _Launcher = TorpedoLauncher(_Craft.index)
    local _Shafts = { _Launcher:getShafts() }

    self.Log(_MethodName, "Adding torpedos directly to launchers.")

    for _ShaftKey, _Shaft in pairs(_Shafts) do
        local _attempts = 0 --Emergency breakout - per shaft. Sometimes placing a torpedo in a shaft just doesn't work and I have no idea why. There's no error or anything.
        local _initialFreeSlots = _Launcher:getFreeSlots(_Shaft) --For some reason the game will register nonexistent shafts as having 15 free slots. It's fucking wack.
        while _Launcher:getFreeSlots(_Shaft) > 0 and _initialFreeSlots ~= 15 and _attempts < 100 do
            _Launcher:addTorpedo(_Torpedo, _Shaft)
            _attempts = _attempts + 1
        end
        self.Log(_MethodName, "Made " .. tostring(_attempts) .. " attempts with shaft " .. tostring(_ShaftKey), false)
    end

    self.Log(_MethodName, "Adding torpeodes to storage.")

    local _storageattempts = 0 --Second emergency breakout
    while _Launcher.freeStorage > _Torpedo.size and _storageattempts < 1000 do
        _Launcher:addTorpedo(_Torpedo)
        _storageattempts = _storageattempts + 1
    end
    self.Log(_MethodName, "Made " .. tostring(_storageattempts) .. " storage attempts.", false)

    local _Ship = Entity()
    Sector():broadcastChatMessage(_Ship, ChatMessageType.Chatter, "Rearming complete! You're good to go, Cavalier!")
    local _Rgen = ESCCUtil.getRand()
    _Ship:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
end
callable(CavaliersTorpedoLoader, "loadSelectedTorpedoes")

--endregion

--region #LOAD TORPEDO TYPES -- these are CLIENT ONLY calls. We need to tell the server what kind of torpedoes to load.

function CavaliersTorpedoLoader.OnLoadNuclearTorpedoes()
    local _MethodName = "On Load Nuclear Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Nuclear)
end

function CavaliersTorpedoLoader.OnLoadNeutronTorpedoes()
    local _MethodName = "On Load Neutron Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Neutron)
end

function CavaliersTorpedoLoader.OnLoadFusionTorpedoes()
    local _MethodName = "On Load Fusion Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Fusion)
end

function CavaliersTorpedoLoader.OnLoadTandemTorpedoes()
    local _MethodName = "On Load Tandem Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Tandem)
end

function CavaliersTorpedoLoader.OnLoadKineticTorpedoes()
    local _MethodName = "On Load Kinetic Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Kinetic)
end

function CavaliersTorpedoLoader.OnLoadIonTorpedoes()
    local _MethodName = "On Load Ion Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Ion)
end

function CavaliersTorpedoLoader.OnLoadPlasmaTorpedoes()
    local _MethodName = "On Load Plasma Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Plasma)
end

function CavaliersTorpedoLoader.OnLoadSabotTorpedoes()
    local _MethodName = "On Load Sabot Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.Sabot)
end

function CavaliersTorpedoLoader.OnLoadEMPTorpedoes()
    local _MethodName = "On Load EMP Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.EMP)
end

function CavaliersTorpedoLoader.OnLoadAntimatterTorpedoes()
    local _MethodName = "On Load Antimatter Torpedoes"
    local _Player = Player()

    invokeServerFunction("CalculateTorpedoPrice", _Player.index, WarheadType.AntiMatter)
end

function CavaliersTorpedoLoader.OnLoadTorpedoesConfirmed()
    local _MethodName = "On Load Torpedoes Confirmed"
    self.Log(_MethodName, "Calling on Client => Invoking on Server")
    local _Player = Player()

    invokeServerFunction("loadSelectedTorpedoes", _Player.index)
end

--endregion

--region #CLIENT / SERVER CALLS

function CavaliersTorpedoLoader.getStringForType(_Type)
    local _MethodName = "Get String For Type"
    self.Log(_MethodName, "_Type is " .. tostring(_Type))

    local _TypeTable = {}
    _TypeTable[WarheadType.Nuclear] = "Nuclear"
    _TypeTable[WarheadType.Neutron] = "Neutron"
    _TypeTable[WarheadType.Fusion] = "Fusion"
    _TypeTable[WarheadType.Tandem] = "Tandem"
    _TypeTable[WarheadType.Kinetic] = "Kinetic"
    _TypeTable[WarheadType.Ion] = "Ion"
    _TypeTable[WarheadType.Plasma] = "Plasma"
    _TypeTable[WarheadType.Sabot] = "Sabot"
    _TypeTable[WarheadType.EMP] = "EMP"
    _TypeTable[WarheadType.AntiMatter] = "AntiMatter"

    return _TypeTable[_Type]
end

function CavaliersTorpedoLoader.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[Cavaliers Torpedo Loader] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion