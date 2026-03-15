package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LOTWLiasonMission2Dialog1
LOTWLiasonMission2Dialog1 = {}

-- make the NPC talk to players
LOTWLiasonMission2Dialog1 = include("npcapi/singleinteraction")
MissionUT = include("missionutility")

include("stringutility")

local data = LOTWLiasonMission2Dialog1.data
data.closeableDialog = false

function LOTWLiasonMission2Dialog1.getDialog()
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    local _PlayerName = Player().name

    local _Talker = "Посредник"

    --d0
    d0.text = "Отличная работа, " .. _PlayerName .. ". Теперь, когда их линии снабжения нарушены, пиратам придётся действовать."
    d0.talker = _Talker
    d0.followUp = d1
    --d1
    d1.text = "Мы будем следить за возможностями дальнейшего срыва их операции. Скорее всего, босса удастся выманить на открытое пространство в ближайшие дни. А пока ждите новых заданий."
    d1.talker = _Talker
    d1.followUp = d2
    --d2
    d2.text = "Как и обещали, все права на добычу — ваши. Сейчас мы передаём лицензию на любой груз в вашем отсеке."
    d2.talker = _Talker
    d2.followUp = d3

    d3.text = "Предупреждаю: это разовая лицензия и не действует в будущем. Пожалуйста, не занимайтесь нелицензионной контрабандой на нашей территории."
    d3.talker = _Talker
    d3.onEnd = "onEnd"

    return d0
end

function LOTWLiasonMission2Dialog1.onEnd()
    Player():invokeFunction("player/missions/lotw/lotwstory2.lua", "lotwStory2_contactedLiason")
end
