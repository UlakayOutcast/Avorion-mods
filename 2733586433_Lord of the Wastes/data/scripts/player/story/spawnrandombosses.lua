local Swenks = include("story/swenks")

local LOTW_onSectorEntered = SpawnRandomBosses.onSectorEntered
function SpawnRandomBosses.onSectorEntered(player, x, y, changeType)
    LOTW_onSectorEntered(player, x, y, changeType)

    if not (changeType == SectorChangeType.Jump) and not (changeType == SectorChangeType.Switch) then return end
    if noSpawnTimer > 0 then return end
    if self.getSpawningDisabled(x, y) then return end

    self.trySpawningSwenks(player, x, y)
end

function SpawnRandomBosses.trySpawningSwenks(_Player, _X,  _Y)
    local _Dist = length(vec2(_X, _Y))
    local _Spawn
    local _Sector = Sector()
    local _PlayerObj = Player(_Player)

    if _PlayerObj:getValue("_lotw_story_complete") and _Dist > 430 then
        local _Specs = SectorSpecifics()
        local regular, offgrid, blocked, home = _Specs:determineContent(_X, _Y, Server().seed)

        if not regular and not offgrid and not blocked and not home then
            self.consecutiveJumps = self.consecutiveJumps + 1

            if random():test(0.04) or self.consecutiveJumps >= 10 then
                _Spawn = true
                -- on spawn reset the jump counter
                self.consecutiveJumps = 0
            end
        elseif regular then
            -- when jumping into the "wrong" sector, reset the jump counter
            self.consecutiveJumps = 0
        end
    end

    if not _Spawn then
        return
    end
    if _Sector:getEntitiesByScript("data/scripts/entity/story/missionadventurer.lua") then
        return
    end
    --Don't spawn these in a sector with stations.
    local _Stations = {_Sector:getEntitiesByType(EntityType.Station)}
    if #_Stations > 0 then
        return
    end

    self.spawnSwenks(_PlayerObj, _X, _Y)
end

function SpawnRandomBosses.spawnSwenks(_Player, _X, _Y)
    Swenks.spawn(_Player, _X, _Y)
end

function SpawnRandomBosses.onSwenksDestroyed()
    noSpawnTimer = 30 * 60
end