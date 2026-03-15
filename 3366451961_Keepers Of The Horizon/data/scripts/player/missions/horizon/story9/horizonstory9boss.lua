package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HorizonStory9Boss
HorizonStory9Boss = {}
local self = HorizonStory9Boss

function HorizonStory9Boss.initialize()
    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/horizon/fs2aim.ogg")
    end
end