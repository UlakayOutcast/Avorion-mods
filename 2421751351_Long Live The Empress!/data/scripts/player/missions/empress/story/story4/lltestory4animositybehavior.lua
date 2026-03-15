package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LLTEStory4AnimosityBehavior
LLTEStory4AnimosityBehavior = {}
local self = LLTEStory4AnimosityBehavior

function LLTEStory4AnimosityBehavior.initialize()
    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/special/maverick.ogg")
    end

    if onServer() then
        ShipAI():setAggressive()
    end
end