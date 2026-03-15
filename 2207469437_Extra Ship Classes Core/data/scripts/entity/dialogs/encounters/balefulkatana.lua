package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace KatanaAmbushLeader
KatanaAmbushLeader = {}

-- make the NPC talk to players
KatanaAmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function KatanaAmbushLeader.getDialog()
    return {text = "You would forego our mercy? Then suffer by our baleful blade!"}
end