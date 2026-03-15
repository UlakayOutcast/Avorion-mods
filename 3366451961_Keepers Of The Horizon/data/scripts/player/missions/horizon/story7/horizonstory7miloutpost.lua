package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HorizonStory7MilOutpost
HorizonStory7MilOutpost = {}
local self = HorizonStory7MilOutpost

function HorizonStory7MilOutpost.initialize()
    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/horizon/fs2bpintodarkv1.ogg")
    end
end

function HorizonStory7MilOutpost.switchTracks()
    if onClient() then
        --print("invoking switch tracks")
        unregisterBoss(Entity().index)
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/horizon/fs2bpviolence.ogg")
    end
end