if onServer() then

local _Debug = 0

local IncreasingThreat_initialize = PassivePlayerAttackStarter.initialize
function PassivePlayerAttackStarter.initialize(_Interdict)
    _Interdict = _Interdict or { x = -1, y = -1 }

    local entityInfos = {}
    local player = Player()
    local galaxy = Galaxy()

    local _vidx = "_increasingthreat_oos_attack_attempts"
    local _Attempts = player:getValue(_vidx) or 0
    if _Attempts > 5 then
        --Don't try more than 5 times - reset and terminate.
        if _Debug == 1 then
            print("Tried to attack oos too many times - terminating - OOS attempts will be reset in approx. 1 minute.")
        end
        terminate()
    else
        player:setValue(_vidx, _Attempts + 1)
    end
    if _Debug == 1 then
        print("Attempt " .. tostring(_Attempts) .. " to attack OOS")
    end

    for _, name in pairs({player:getShipNames()}) do
        local info = {}
        local entry = ShipDatabaseEntry(player.index, name)
        if entry:getAvailability() == ShipAvailability.Available then
            local x, y = player:getShipPosition(name)
            local _Interdicted = false
            if _Interdict.x == x and _Interdict.y == y then
                _Interdicted = true
            end

            if galaxy:sectorLoaded(x, y) and not _Interdicted then
                info = {x = x, y = y, name = name}
                -- add coordinates to table so that sectors with several stations end up in table more often, making attack more likely there
                table.insert(entityInfos, info)
            end
        end
    end

    -- find a random sector with player stations to be attacked
    local targetEntity = getRandomEntry(entityInfos)

    local spawnAttackers = [[
    function run(...)
        Sector():addScriptOnce("data/scripts/events/passiveplayerattack.lua", ...)
    end
    ]]

    if targetEntity then
        runSectorCode(targetEntity.x, targetEntity.y, true, spawnAttackers, "run", player.index, targetEntity.name)
    end

    terminate()
end

end