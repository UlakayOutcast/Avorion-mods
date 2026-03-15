package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HunterAmbushLeader
HunterAmbushLeader = {}

-- make the NPC talk to players
HunterAmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function HunterAmbushLeader.getDialog()
    return {text = "Run now, and we'll give you a head start."}
end