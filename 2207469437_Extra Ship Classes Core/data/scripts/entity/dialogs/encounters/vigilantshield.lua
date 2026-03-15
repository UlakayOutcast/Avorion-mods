package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ShieldAmbushLeader
ShieldAmbushLeader = {}

-- make the NPC talk to players
ShieldAmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function ShieldAmbushLeader.getDialog()
    return {text = "What's a mob to a King?"}
end