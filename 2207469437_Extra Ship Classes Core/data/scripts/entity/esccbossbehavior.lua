package.path = package.path .. ";data/scripts/lib/?.lua"

ESCCUtil = include("esccutil")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace IncreasingThreatBossBehavior
IncreasingThreatBossBehavior = {}
local self = IncreasingThreatBossBehavior

self._Debug = 0

self._Data = {}
self._Data._BossType = nil

local _Taunts = {
    { "No matter the cost, you must be dealt with.", "Like animals to the slaughter, we shall cut you down.", "Surrender now and perhaps we will show mercy.", "Before our blade, you are nothing." }, --Katana
    { "Float like a butterfly...", "You can't hit what you can't catch!", "Catch us if you can!", "Can you keep up?" }, --Goliath
    { "Ready to rip!", "Rip and tear!", "Rend! Maim! Kill!", "We'll tear you to pieces!", "Our claws will make short work of you!" }, --Hellcat
    { "Time for you to start running...", "Run as far as you'd like. You won't escape.", "You can't escape from us.", "Feeling tired? We're just getting started." }, --Hunter
    { "Our defense is absolute.", "The best offense is a flawless defense.", "You can't tear down this wall!", "Clad in armor, we are invincible!" }, --Shield
    { "There's no need to fear the inevitable...", "Burn!", "We shall bathe this sector in flames.", "We didn't start the fire...", "Can't stop the fire!" } --Phoenix
}

function IncreasingThreatBossBehavior.initialize(_BossType)
    local _MethodName = "Initialize"
    self._Data._BossType = _BossType

    self.Log(_MethodName, "Boss type is " .. tostring(self._Data._BossType))

    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/special/givingchase.ogg")
    end

    if onServer() then
        ShipAI():setAggressive()
    end
end

function IncreasingThreatBossBehavior.getUpdateInterval()
    return 120
end

function IncreasingThreatBossBehavior.updateServer()
    local _MethodName = "Update Server"
    local _Rgen = ESCCUtil.getRand()

    if _Rgen:getInt(1, 2) == 1 then
        self.Log(_MethodName, "Boss type is " .. tostring(self._Data._BossType))
        local _MsgTable = _Taunts[self._Data._BossType]
        local _Msg = _MsgTable[_Rgen:getInt(1, #_MsgTable)]

        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, _Msg)
    end
end

--region #CLIENT / SERVER CALLS

function IncreasingThreatBossBehavior.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[IT Boss Behavior] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function IncreasingThreatBossBehavior.secure()
    local _MethodName = "Secure"
    return self._Data
end

function IncreasingThreatBossBehavior.restore(_Values)
    local _MethodName = "Restore"
    self._Data = _Values
end

--endregion