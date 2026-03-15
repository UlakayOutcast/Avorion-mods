package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LLTEStory4Animosity
LLTEStory4Animosity = {}

-- make the NPC talk to players
LLTEStory4Animosity = include("npcapi/singleinteraction")
MissionUT = include("missionutility")

include("stringutility")

local data = LLTEStory4Animosity.data
data.closeableDialog = false

function LLTEStory4Animosity.getDialog()
    local _Talker = "Adriana Stahl"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    local _AnimosityTalker = "Animosity"
    local _AnimosityTalkerColor = MissionUT.getDialogTalkerColor2()
    local _AnimosityTextColor = MissionUT.getDialogTalkerColor2()

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}

    --d0
    d0.text = "Did you think we had forgotten? What you've done to us? What you've done to our comrades?"
    d0.talker = _AnimosityTalker
    d0.textColor =  _AnimosityTalkerColor
    d0.talkerColor = _AnimosityTextColor
    d0.followUp = d1
    --d1
    d1.text = "No."
    d1.talker = _AnimosityTalker
    d1.textColor =  _AnimosityTalkerColor
    d1.talkerColor = _AnimosityTextColor
    d1.followUp = d2
    --d2
    d2.text = "Thousands dead. And for what? So you can prove you've got the biggest guns in the galaxy? That you can crush a ragtag group abandoned by the galactic order?"
    d2.talker = _AnimosityTalker
    d2.textColor =  _AnimosityTalkerColor
    d2.talkerColor = _AnimosityTextColor
    d2.followUp = d3
    --d3
    d3.text = "You don't get to claim the moral high ground! You extort! You steal! You enslave!"
    d3.talker = _Talker
    d3.textColor = _TextColor
    d3.talkerColor = _TalkerColor
    d3.followUp = d4
    --d4
    d4.text = "The galactic order abandoned you? Fine, but that's not an excuse to become monsters. There are ways to survive that don't involve running down defenseless ships and slaughtering the entire crew!"
    d4.talker = _Talker
    d4.textColor = _TextColor
    d4.talkerColor = _TalkerColor
    d4.followUp = d5
    --d5
    d5.text = "Hmph. We shouldn't have expected anything but self-righteous drivel from you, Empress."
    d5.talker = _AnimosityTalker
    d5.textColor =  _AnimosityTalkerColor
    d5.talkerColor = _AnimosityTextColor
    d5.followUp = d6
    --d6
    d6.text = "We do what we have to in order to survive. But today, we'll settle for vengeance. All ships, drop out of subspace now!"
    d6.talker = _AnimosityTalker
    d6.textColor =  _AnimosityTalkerColor
    d6.talkerColor = _AnimosityTextColor
    d6.onEnd = "onEnd"

    return d0
end

function LLTEStory4Animosity.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission4.lua", "onPhase4Dialog1End")
end