package.path = package.path .. ";data/scripts/lib/?.lua"

-- Не удаляйте и не изменяйте следующий комментарий, он указывает пространство имён скрипта. Без него скрипт сломается.
-- namespace LLTESide3Dialogue1
LLTESide3Dialogue1 = {}

-- Заставляем NPC разговаривать с игроками
LLTESide3Dialogue1 = include("npcapi/singleinteraction")
MissionUT = include("missionutility")
ESCCUtil = include("esccutil")

include("stringutility")

local data = LLTESide3Dialogue1.data
data.closeableDialog = false

function LLTESide3Dialogue1.getDialog()
    local d0 = {}
    local d1 = {}
    local d2 = {}

    local _Rgen = ESCCUtil.getRand()

    local _Possibled0Messages = {
        "Вы здесь от имени Кавалеров, да?",
        "Вижу, приспешник Императора наконец-то соизволил показаться.",
        "Не волнуйтесь, мы и так знаем, зачем вы здесь."
    }
    local _Possibled1Messages = {
        "Вы хотите подчинить себе всю галактику.",
        "Вам разве мало того, что вы уже забрали?",
        "Нам следовало знать, что вы придёте за нами следующими.",
        "Вам мало крови, пролитой за ваши богатства?",
        "Как долго, по-вашему, это продлится, прежде чем вы всё потеряете?"
    }
    local _Possibled2Messages = {
        "Мы никогда не преклоним перед вами колени, тиран!",
        "Мы лучше умрём, чем подчинимся вашему правлению!",
        "Мы убьём каждого из вас или умрём в попытке!",
        "Вы никогда не отнимете нашу свободу!",
        "Мы вызываем ваш блеф. Пора падать вам!"
    }

    -- d0
    d0.text = _Possibled0Messages[_Rgen:getInt(1, #_Possibled0Messages)]
    d0.followUp = d1
    -- d1
    d1.text = _Possibled1Messages[_Rgen:getInt(1, #_Possibled1Messages)]
    d1.followUp = d2
    -- d2
    d2.text = _Possibled2Messages[_Rgen:getInt(1, #_Possibled2Messages)]
    d2.onEnd = "onEnd"

    return d0
end

function LLTESide3Dialogue1.onEnd()
    Player():invokeFunction("player/missions/empress/side/lltesidemission3.lua", "factionDeclareWar")
end
