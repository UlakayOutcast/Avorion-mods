package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HorizonStory3MiniBoss
HorizonStory3MiniBoss = {}
local self = HorizonStory3MiniBoss

self._Debug = 0

function HorizonStory3MiniBoss.initialize()
    local _MethodName = "Initialize"

    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/special/lasselyxminiboss.ogg", nil, true)
    end
end

function HorizonStory3MiniBoss.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 3 Miniboss] - [" .. _MethodName .. "] - " .. _Msg)
    end
end