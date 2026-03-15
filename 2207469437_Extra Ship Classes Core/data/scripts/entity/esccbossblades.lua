package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ESCCBossBlades
ESCCBossBlades = {}
local self = ESCCBossBlades

function ESCCBossBlades.initialize()
    local _MethodName = "Initialize"

    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/special/bladesedge.ogg")
    end

    if onServer() then
        ShipAI():setAggressive()
    end
end