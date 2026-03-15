package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HellcatAmbushLeader
HellcatAmbushLeader = {}

-- make the NPC talk to players
HellcatAmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function HellcatAmbushLeader.getDialog()
    return {text = "Our pound of flesh? We'll rend it from your carcass!"}
end