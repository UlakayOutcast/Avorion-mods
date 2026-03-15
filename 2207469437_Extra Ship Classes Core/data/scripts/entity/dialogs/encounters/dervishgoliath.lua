package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace GoliathAmbushLeader
GoliathAmbushLeader = {}

-- make the NPC talk to players
GoliathAmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function GoliathAmbushLeader.getDialog()
    return {text = "Dance to the song of ringing steel!"}
end