package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LLTEStory2PirateSector
LLTEStory2PirateSector = {}

-- make the NPC talk to players
LLTEStory2PirateSector = include("npcapi/singleinteraction")
MissionUT = include("missionutility")

include("stringutility")

local data = LLTEStory2PirateSector.data
data.closeableDialog = false

function LLTEStory2PirateSector.getDialog()
    local d0 = {}
    local d1 = {}
    local d2 = {}
    
    local _Talker = "Adriana Stahl"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    --d0
    d0.text = "We should have known it was only a matter of time until you Cavaliers came for us."
    d0.followUp = d1
    --d1
    d1.text = "We won't tolerate scum like you preying on innocents. This ends today!"
    d1.talker = _Talker
    d1.textColor = _TextColor
    d1.talkerColor = _TalkerColor
    d1.followUp = d2
    --d2
    d2.text = "Yes, for you! Get ready to die, Cavalier!"
    d2.onEnd = "onEnd"

    return d0
end

function LLTEStory2PirateSector.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission2.lua", "startTheBattle")
end