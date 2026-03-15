package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HorizonStory6Boss
HorizonStory6Boss = {}
local self = HorizonStory6Boss

function HorizonStory6Boss.initialize()
    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/horizon/fs2bpfighter3.ogg")
    end
end