package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LOTWLiasonMission1Dialog1
LOTWLiasonMission1Dialog1 = {}

-- make the NPC talk to players
LOTWLiasonMission1Dialog1 = include("npcapi/singleinteraction")
MissionUT = include("missionutility")

include("stringutility")

local data = LOTWLiasonMission1Dialog1.data
data.closeableDialog = false

function LOTWLiasonMission1Dialog1.getDialog()
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    local _PlayerName = Player().name

    local _Talker = "Посредник"

    --d0
    d0.text = "Хорошая работа, " .. _PlayerName .. ". Эти пираты могли стать серьёзной угрозой, если бы им позволили бесконтрольно терроризировать сектор."
    d0.talker = _Talker
    d0.followUp = d1
    --d1
    d1.text = "Особенно досаждает один пиратский босс, который считает, что здесь он хозяин. Только потому, что мы на окраине галактики, не значит, что у нас нет порядка. Мы обязаны поддерживать безопасность в этих секторах."
    d1.talker = _Talker
    d1.followUp = d2
    --d2
    d2.text = "Хотели бы нанять вас для дальнейшей работы. Нам нужно выкурить эту нечисть и уничтожить её раз и навсегда. Что скажете?"
    d2.talker = _Talker
    d2.answers = {
        { answer = "Конечно, помогу.", followUp = d4 },
        { answer = "Звучит как головная боль. Откажусь.", followUp = d3 }
    }

    d3.text = "Но почему? Мы заплатим вам гораздо больше, чем за любую другую работу в этом регионе, и вы получите полные права на всё, что найдёте. Если вы так упорно избегаете лёгких денег — что ж, не принимайте контракт."
    d3.talker = _Talker
    d3.onEnd = "onEnd"

    d4.text = "Отлично! Мы свяжемся с вами."
    d4.talker = _Talker
    d4.onEnd = "onEnd"

    return d0
end

function LOTWLiasonMission1Dialog1.onEnd()
    Player():invokeFunction("player/missions/lotw/lotwstory1.lua", "lotwStory1_contactedLiason")
end
