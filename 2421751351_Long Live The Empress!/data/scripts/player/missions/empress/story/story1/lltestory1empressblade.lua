package.path = package.path .. ";data/scripts/lib/?.lua"

-- Не удаляйте и не изменяйте следующий комментарий, он сообщает игре пространство имён, в котором находится этот скрипт. Если вы удалите его, скрипт сломается.
-- namespace LLTEStory1EmpressBlade
LLTEStory1EmpressBlade = {}

-- заставляем NPC разговаривать с игроками
LLTEStory1EmpressBlade = include("npcapi/singleinteraction")
MissionUT = include("missionutility")

include("stringutility")

local data = LLTEStory1EmpressBlade.data
data.closeableDialog = false

function LLTEStory1EmpressBlade.getDialog()
    local d0 = {}
    local d1 = {}
    local d2 = {}

    local _PlayerRank = Player():getValue("_llte_cavaliers_rank")
    local _PlayerName = Player().name

    local _Talker = "Адриана Сталь"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    -- d0
    d0.text = _PlayerRank .. " " .. _PlayerName .. "! Рада, что вы смогли прийти. Как видите, мы тоже не сидели без дела."
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor
    d0.answers = {
        { answer = "Это видно.", followUp = d1 }
    }
    -- d1
    d1.text = "Поскольку вы перехватили их грузы и добыли необходимые материалы, мы почти готовы атаковать пиратскую крепость. Осталось только разобраться с контейнерами и организовать остальной флот."
    d1.talker = _Talker
    d1.textColor = _TextColor
    d1.talkerColor = _TalkerColor
    d1.followUp = d2
    -- d2
    d2.text = "Я свяжусь с вами, когда будем готовы начать штурм. Надеюсь, мы можем рассчитывать на вашу поддержку!"
    d2.talker = _Talker
    d2.textColor = _TextColor
    d2.talkerColor = _TalkerColor
    d2.answers = {
        { answer = "Я буду там.", onSelect = "onEnd" }
    }

    return d0
end

function LLTEStory1EmpressBlade.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission1.lua", "contactedAdriana")
end
