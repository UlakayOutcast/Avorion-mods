package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")
MissionUT = include("missionutility")

--Let's try namespacing this. I want to see what happens.
--namespace LLTEStory2Dialogue1
LLTEStory2Dialogue1 = {}
local self = LLTEStory2Dialogue1

self._Data = {}

self._Debug = 0

--region #INIT

function LLTEStory2Dialogue1.initialize(_X, _Y)
    local _MethodName = "Initialize"
    if onServer() then
        _MethodName = _MethodName .. " SERVER"
        self.Log(_MethodName, "Calling on Server - setting self._Data")

        self._Data._X = _X
        self._Data._Y = _Y
    else
        _MethodName = _MethodName .. " CLIENT"
        self.Log(_MethodName, "Calling on Client - syncing")

        self.sync()
    end
end

--endregion

--region #CLIENT CALLS

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function LLTEStory2Dialogue1.interactionPossible(playerIndex)
    local _MethodName = "Interaction Possible"
    self.Log(_MethodName, "Determining interactability with " .. tostring(playerIndex))
    local _Player = Player(playerIndex)

    self._PlayerIndex = playerIndex

    local craft = _Player.craft
    if craft == nil then return false end

    return true
end

function LLTEStory2Dialogue1.initUI()
    ScriptUI():registerInteraction("[Hail]"%_t, "onContact", 99)
end

function LLTEStory2Dialogue1.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function LLTEStory2Dialogue1.getDialog()
    local _MethodName = "Get Dialogue"
    self.Log(_MethodName, "Beginning...")

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    local _Player = Player(self._PlayerIndex)
    local _PlayerName = _Player.name
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")
    local _PlayerFailedStory2 = _Player:getValue("_llte_failedstory2")

    local _Talker = "Adriana Stahl"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    --d1
    d0.text = _PlayerRank .. " " .. _PlayerName .. "! We can move out at moment's notice. Are you ready?"
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor
    d0.answers = {}
    table.insert(d0.answers, { answer = "I'm ready.", followUp = d1 })
    if _PlayerFailedStory2 then
        table.insert(d0.answers, { answer = "I'm ready... but can you send additional reinforcements this time?", followUp = d3 })
    end
    table.insert(d0.answers, { answer = "I need more time.", followUp = d2 })
    --d1
    d1.text = "Excellent! We'll meet in (" .. self._Data._X .. ":" .. self._Data._Y .. "). It's time to put an end to this."
    d1.talker = _Talker
    d1.textColor = _TextColor
    d1.talkerColor = _TalkerColor
    d1.onEnd = "onEnd"
    --d2
    d2.text = "No problem - go make sure you're prepared. We don't know what they've got in store for us."
    d2.talker = _Talker
    d2.textColor = _TextColor
    d2.talkerColor = _TalkerColor
    --d3
    d3.text = "I'm sure that I can arrange something! We'll meet in (" .. self._Data._X .. ":" .. self._Data._Y .. "). It's time to put an end to this."
    d3.talker = _Talker
    d3.textColor = _TextColor
    d3.talkerColor = _TalkerColor
    d3.onEnd = "onEndHelp"

    return d0
end

function LLTEStory2Dialogue1.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission2.lua", "saidReady")
end

function LLTEStory2Dialogue1.onEndHelp()
    Player():invokeFunction("player/missions/empress/story/lltestorymission2.lua", "saidReadyHelp")
end

--endregion

--region #CLIENT / SERVER CALLS

function LLTEStory2Dialogue1.sync(_X, _Y)
    local _MethodName = "Sync"

    if onClient() then
        _MethodName = _MethodName .. " CLIENT"
        self.Log(_MethodName, "Beginning...")
        if _X and _Y then
            self.Log(_MethodName, "Got coordinates. X is " .. tostring(_X) .. " and Y is " .. tostring(_Y))
            self._Data._X = _X
            self._Data._Y = _Y
        else
            invokeServerFunction("sync")
        end
    else
        _MethodName = _MethodName .. " SERVER"
        self.Log(_MethodName, "Beginning...")

        broadcastInvokeClientFunction("sync", self._Data._X, self._Data._Y)
    end
end
callable(LLTEStory2Dialogue1, "sync")

function LLTEStory2Dialogue1.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Story 2 Dialog] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion

--region #SECURE / RESTORE

function LLTEStory2Dialogue1.secure()
    return self._Data
end

function LLTEStory2Dialogue1.restore(_Values)
    self._Data = _Values
end

--endregion