package.path = package.path .. ";data/scripts/lib/?.lua"

-- Не удаляйте и не изменяйте следующий комментарий, он сообщает игре пространство имён, в котором находится этот скрипт. Если вы удалите его, скрипт сломается.
-- namespace LLTEStory1AmbushLeader
LLTEStory1AmbushLeader = {}

-- заставляем NPC разговаривать с игроками
LLTEStory1AmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function LLTEStory1AmbushLeader.getDialog()
    return { text = "Ха, кажется, мы нашли заблудшего! Я знал, что откупиться от того контрабандиста была хорошая идея. Хватайте их!" }
end
