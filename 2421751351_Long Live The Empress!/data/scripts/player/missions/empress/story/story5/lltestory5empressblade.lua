package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")
MissionUT = include("missionutility")
ESCCUtil = include("esccutil")

--Let's try namespacing this. I want to see what happens.
--namespace LLTEStory5EmpressBlade1
LLTEStory5EmpressBlade1 = {}
local self = LLTEStory5EmpressBlade1

self._Data = {}

self._Debug = 0

--region #INIT

function LLTEStory5EmpressBlade1.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Beginning...")
end

--endregion

--region #CLIENT CALLS

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function LLTEStory5EmpressBlade1.interactionPossible(playerIndex)
    local _MethodName = "Interaction Possible"
    self.Log(_MethodName, "Determining interactability with " .. tostring(playerIndex))
    local _Player = Player(playerIndex)

    self._PlayerIndex = playerIndex

    local craft = _Player.craft
    if craft == nil then return false end

    return true
end

function LLTEStory5EmpressBlade1.initUI()
    ScriptUI():registerInteraction("[Hail]"%_t, "onContact", 99)
end

function LLTEStory5EmpressBlade1.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function LLTEStory5EmpressBlade1.getDialog()
    --At the start of the mission.
    local _MethodName = "Get Dialog"
    self.Log(_MethodName, "Running getDialog")

    local d0 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}
    local d9 = {}
    local d10 = {}
    local d11 = {}

    local _Talker = "Adriana Stahl"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    local _Talker2 = "Research"
    local _TalkerColor2 = ESCCUtil.getSaneColor(60, 100, 60)
    local _TextColor2 = ESCCUtil.getSaneColor(60, 100, 60)
    
    local _Player = Player()
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")
    local _PlayerName = _Player.name

    --d0
    d0.text = "Hello, " .. _PlayerRank .. "! What's the word?"
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor
    d0.answers = {
        { answer = "Let's do this. You said you had a plan?", followUp = d3 },
        { answer = "Never mind." }
    }
    
    d3.text = "Yes! I was talking about the artifact with our research team. We think we can set it up to draw some Xsotan-"
    d3.talker = _Talker
    d3.textColor = _TextColor
    d3.talkerColor = _TalkerColor
    d3.followUp = d4
    
    d4.text = "Research deck? This is the bridge. We've got power fluctuations in your area and the hangar bay. Are you running any tests?"
    d4.talker = _Talker
    d4.textColor = _TextColor
    d4.talkerColor = _TalkerColor
    d4.followUp = d5
    
    d5.text = "Not that I know of, bridge. Let me che-"
    d5.talker = _Talker2
    d5.textColor = _TextColor2
    d5.talkerColor = _TalkerColor2
    d5.followUp = d6
    
    d6.text = "What's going on down there? Fluctuations are spreading all across the ship!"
    d6.talker = _Talker
    d6.textColor = _TextColor
    d6.talkerColor = _TalkerColor
    d6.followUp = d7
    
    d7.text = "Uhh... I don't know... give me a second. We were examining the artifact, and had just started scans and..."
    d7.talker = _Talker2
    d7.textColor = _TextColor2
    d7.talkerColor = _TalkerColor2
    d7.followUp = d8
    
    d8.text = "Subspace readings are off the charts! What have you done?!"
    d8.talker = _Talker
    d8.textColor = _TextColor
    d8.talkerColor = _TalkerColor
    d8.followUp = d9
    
    d9.text = "The artifact turned itself on! We don't know what it's doing! You have to cut power to the research decks!"
    d9.talker = _Talker2
    d9.textColor = _TextColor2
    d9.talkerColor = _TalkerColor2
    d9.followUp = d10
    
    d10.text = "... Bridge to all stations! Emergency shutdown procedures engaged!"
    d10.talker = _Talker
    d10.textColor = _TextColor
    d10.talkerColor = _TalkerColor
    d10.followUp = d11
    
    d11.text = "CUT IT OFF!"
    d11.talker = _Talker2
    d11.textColor = _TextColor2
    d11.talkerColor = _TalkerColor2
    d11.onEnd = "onEnd"

    return d0
end

function LLTEStory5EmpressBlade1.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission5.lua", "onPhase2DialogEndYes")
end

--endregion

--region #CLIENT / SERVER CALLS

function LLTEStory5EmpressBlade1.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Story 5 Empress Blade 1] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion