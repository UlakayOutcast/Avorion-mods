package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace PhoenixAmbushLeader
PhoenixAmbushLeader = {}

-- make the NPC talk to players
PhoenixAmbushLeader = include("npcapi/singleinteraction")

include("stringutility")

function PhoenixAmbushLeader.getDialog()
    return {text = "Some fear the fire. Some simply become it."}
end