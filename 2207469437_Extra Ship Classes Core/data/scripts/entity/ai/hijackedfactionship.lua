package.path = package.path .. ";data/scripts/lib/?.lua"

ESCCUtil = include("esccutil")

--namespace AIHijackedShip
AIHijackedShip = {}
local self = AIHijackedShip

self._Data = {} --Want this on both client and server.
--[[
    Here's a guide to how this thing works:
        _TimeToActive       = Time until this becomes active. Default to 20 seconds.
        _RegisteredEnemies  = Track whether or not enemies have been registered.
        _AttemptToRunChance = Set to a float. Determines the % chance that the ship will try to escape when exposed. Defaults to 0.25. 1.0 means ship will always try to run.
]]

function AIHijackedShip.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing AI Hijacked Ship v2 script on entity.")

    if Entity().playerOrAllianceOwned then
        print("ERROR: Cannot place this on a player or alliance ship!")
        terminate()
        return
    end

    self._Data = _Values or {}

    self._Data._TimeToActive = self._Data._TimeToActive or 20
    self._Data._AttemptsToRunChance = self._Data._AttemptsToRunChance or 0.25

    self._Data._ActiveTime = 0
    self._Data._RegisteredEnemies = false
end

function AIHijackedShip.interactionPossible(playerIndex)
    local methodName = "Interaction Possible"

    local player = Player(playerIndex)
    local _Entity = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(_Entity)
    local targetDist = 200
    --if the player has more than one scanner system, idk what happens. why would you have more than one scanner booster
    if craft:hasScript("scannerbooster.lua") or craft:hasScript("superscoutsystem.lua") then
        local scannerRarity = 0
        local scannerBonus = 1
        if craft:hasScript("scannerbooster.lua") then
            local ok, ret = craft:invokeFunction("scannerbooster.lua", "getRarity")
            if ok == 0 then
                scannerRarity = ret.value --Get the rarity tier value rather than the name.
            end
            scannerBonus = scannerBonus + ((5 + scannerRarity) * 0.1) --should give a 40% bonus @ petty, up to a 100% bonus @ legendary
        else
            local ok, ret = craft:invokeFunction("superscoutsystem.lua", "getRarity")
            if ok == 0 then
                scannerRarity = ret.value --Get the rarity tier value rather than the name.
            end
            scannerBonus = scannerBonus + (((5 + scannerRarity) * 0.1) * 0.8) --ITR upgrades are generally worth ~80% a normal upgrade.
        end

        self.Log(methodName, "Craft has scanner booster - rarity is: " .. tostring(scannerRarity) .. " final bonus is: " .. tostring(scannerBonus))

        targetDist = math.floor(targetDist * scannerBonus)
    end
    

    if dist < targetDist then
        return true
    else
        return false, "You're not close enough to scan this ship."
    end
end

function AIHijackedShip.initUI()
    ScriptUI():registerInteraction("[Scan]"%_t, "onScanSelected");
end

function AIHijackedShip.onScanSelected()
    invokeServerFunction("onScanSelectedServer")
end

function AIHijackedShip.onScanSelectedServer()
    local _Sector = Sector()
    local x, y = _Sector:getCoordinates()
    local _pLevel = Balancing_GetPirateLevel(x, y)
    local _pFaction = Galaxy():getPirateFaction(_pLevel)

    local _entity = Entity()

    _entity.factionIndex = _pFaction.index
    _entity:setValue("is_pirate", true)
    _entity:setValue("npc_chatter", nil)

    if random():test(self._Data._AttemptsToRunChance) then
        --Ship attempts to escape.
        local _Messages = {
            "We've been found out! Activate the hyperdrive now!",
            "The locals will tear us to pieces! RUN!",
            "We need to get out! We're sitting ducks here!",
            "Active scan?! Set jump coordinates NOW! GO GO GO!",
            "It's not worth it! We need to get out of here!!"
        }
        shuffle(random(), _Messages)
    
        _Sector:broadcastChatMessage(_entity, ChatMessageType.Chatter, _Messages[1])
        _entity:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
    else
        if random():test(0.5) then
            local _Messages = {
                "IFF exposed?! Damn you!",
                "Guess the honeymoon is over...",
                "Our cover is blown, boys! Give 'em hell!",
                "It seems we've been found out!",
                "Tch! Go down, boot-licker!"
            }
            shuffle(random(), _Messages)
    
            _Sector:broadcastChatMessage(_entity, ChatMessageType.Chatter, _Messages[1])
        end
    end
end
callable(AIHijackedShip, "onScanSelectedServer")

function AIHijackedShip.getUpdateInterval()
    if self._Data._RegisteredEnemies then
        return 30
    else
        return 10
    end
end

function AIHijackedShip.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    self.Log(_MethodName, "Running.")

    self._Data._ActiveTime = self._Data._ActiveTime + _TimeStep
    if self._Data._ActiveTime < self._Data._TimeToActive then
        return
    end

    if not self._Data._RegisteredEnemies then
        self.Log(_MethodName, "Time to active exceeded. Register enemies.")
        self.registerEnemies()
        self._Data._RegisteredEnemies = true
    end
end

function AIHijackedShip.registerEnemies()
    local _MethodName = "Reigster Enemies"
    self.Log(_MethodName, "Running.")

    local _Sector = Sector()
    
    local players = {_Sector:getPlayers()}
    for _, player in pairs(players) do
        local playerentities = {_Sector:getEntitiesByFaction(player.index)}
        for _, playerentity in pairs(playerentities) do
            ShipAI():registerEnemyEntity(playerentity.index)
        end
    end
end

--region #CLIENT / SERVER CALLS

function AIHijackedShip.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[AI Hijacked Ship] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function AIHijackedShip.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function AIHijackedShip.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion