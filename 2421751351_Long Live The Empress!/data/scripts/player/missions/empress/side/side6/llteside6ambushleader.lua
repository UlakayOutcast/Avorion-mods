package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LLTESide6AmbushLeader
LLTESide6AmbushLeader = {}

-- make the NPC talk to players
LLTESide6AmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function LLTESide6AmbushLeader.getDialog()
    return { text = "Так это вы выполняли поручения Кавальерс? Убейте их и заберите этот груз!" }
end