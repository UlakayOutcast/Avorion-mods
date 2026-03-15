package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--See pirategenerator.lua for a better description of exactly what these ships do.
--fairly standard table of spawns by danger level. Scorchers (very dangerous shield-killing ships) don't start showing up until danger level 6.
--Devastators (the ultimate bullet sponge) don't show up until danger level 10.
local dangerLevel_StandardSpawnTables = {
    {Level = 1, Table = {"Outlaw", "Outlaw", "Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate"}},
    {Level = 2, Table = {"Outlaw", "Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder"}},
    {Level = 3, Table = {"Outlaw", "Outlaw", "Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder", "Raider", "Raider"}},
    {Level = 4, Table = {"Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider"}},
    {Level = 5, Table = {"Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider", "Ravager", "Ravager"}},
    {Level = 6, Table = {"Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider", "Ravager", "Ravager", "Scorcher", "Scorcher"}},
    {Level = 7, Table = {"Disruptor", "Disruptor", "Raider", "Raider", "Ravager", "Ravager", "Scorcher", "Scorcher", "Prowler", "Prowler"}},
    {Level = 8, Table = {"Disruptor", "Disruptor", "Raider", "Ravager", "Scorcher", "Scorcher", "Prowler", "Prowler", "Pillager", "Pillager"}},
    {Level = 9, Table = {"Disruptor", "Disruptor", "Scorcher", "Scorcher", "Scorcher", "Prowler", "Prowler", "Prowler", "Pillager", "Pillager"}},
    {Level = 10, Table = {"Disruptor", "Scorcher", "Scorcher", "Scorcher", "Prowler", "Prowler", "Pillager", "Pillager", "Pillager", "Devastator"}}
}
--low threat standard table of spawns by danger level. Custom ships (which are much more dangerous than the standard pirates) aren't even represented until
--threat level 10, where we have a mere 10% chance to spawn a prowler (not that threatening compared to a scorcher, pillager or devastator)
local dangerLevel_LowThreatSpawnTables = {
    {Level = 1, Table = {"Outlaw", "Outlaw", "Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate"}},
    {Level = 2, Table = {"Outlaw", "Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Pirate"}},
    {Level = 3, Table = {"Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Pirate", "Marauder"}},
    {Level = 4, Table = {"Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Pirate", "Marauder", "Marauder"}},
    {Level = 5, Table = {"Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder"}},
    {Level = 6, Table = {"Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider"}},
    {Level = 7, Table = {"Bandit", "Bandit", "Pirate", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider"}},
    {Level = 8, Table = {"Bandit", "Pirate", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider"}},
    {Level = 9, Table = {"Pirate", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider", "Ravager"}},
    {Level = 10, Table = {"Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider", "Ravager", "Prowler"}}
}
--high threat standard table of spawns by danger level. Custom ships show up early and the table caps off with a 50/50 scorcher / devastator split.
local dangerLevel_HighThreatSpawnTables = {
    {Level = 1, Table = {"Outlaw", "Outlaw", "Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate"}},
    {Level = 2, Table = {"Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder"}},
    {Level = 3, Table = {"Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider"}},
    {Level = 4, Table = {"Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider", "Raider", "Ravager", "Ravager", "Ravager"}},
    {Level = 5, Table = {"Marauder", "Raider", "Raider", "Raider", "Ravager", "Ravager", "Ravager", "Scorcher", "Scorcher", "Scorcher"}},
    {Level = 6, Table = {"Raider", "Ravager", "Ravager", "Ravager", "Scorcher", "Scorcher", "Scorcher", "Prowler", "Prowler", "Prowler"}},
    {Level = 7, Table = {"Ravager", "Scorcher", "Scorcher", "Scorcher", "Prowler", "Prowler", "Prowler", "Pillager", "Pillager", "Pillager"}},
    {Level = 8, Table = {"Scorcher", "Scorcher", "Scorcher", "Prowler", "Pillager", "Pillager", "Pillager", "Devastator", "Devastator", "Devastator"}},
    {Level = 9, Table = {"Scorcher", "Scorcher", "Scorcher", "Scorcher", "Pillager", "Pillager", "Devastator", "Devastator", "Devastator", "Devastator"}},
    --50/50 split, so no need for more than this.
    {Level = 10, Table = {"Scorcher", "Devastator"}}
}
--standard table for a faction.
local dangerLevel_factionStandardSpawnTable = {
    {Level = 1, Table = {"L", "L", "L", "L", "L", "L", "L", "L", "L", "L"}},
    {Level = 2, Table = {"L", "L", "L", "L", "L", "L", "L", "L", "M", "M"}},
    {Level = 3, Table = {"L", "L", "L", "L", "L", "L", "M", "M", "M", "M"}},
    {Level = 4, Table = {"L", "L", "L", "L", "M", "M", "M", "M", "M", "M"}},
    {Level = 5, Table = {"L", "L", "M", "M", "M", "M", "M", "M", "M", "M"}},
    {Level = 6, Table = {"M", "M", "M", "M", "M", "M", "M", "M", "M", "M"}},
    {Level = 7, Table = {"M", "M", "M", "M", "M", "M", "M", "M", "H", "H"}},
    {Level = 8, Table = {"M", "M", "M", "M", "M", "M", "H", "H", "H", "H"}},
    {Level = 9, Table = {"M", "M", "M", "M", "H", "H", "H", "H", "H", "H"}},
    {Level = 10, Table = {"M", "M", "H", "H", "H", "H", "H", "H", "H", "H"}}
}

local ESCCUtil = {}
local self = ESCCUtil

self.RandomCalled = 0

self._Debug = 0

--If you want to just get the table to do something with it - such as adding a jammer

--region #WAVE TABLES

function ESCCUtil.getStandardTable(dangerLevel, threatLevel, _Faction)
    local _MethodName = "Get Standardized Spawn Table"
    --Get standard if not specified.
    threatLevel = threatLevel or "Standard"
    _Faction = _Faction or false --Most usages of this will be for pirates.

    ESCCUtil.Log(_MethodName, "Grabbing " .. tostring(threatLevel) .. " table for danger level " .. tostring(dangerLevel))
    --Set which spawn table set we're looking through
    local tbl = {}
    if _Faction then
        ESCCUtil.Log(_MethodName, "Getting faction table.")
        tbl = dangerLevel_factionStandardSpawnTable
    else
        ESCCUtil.Log(_MethodName, "Getting non-faction table.")
        if threatLevel == "Low" then
            tbl = dangerLevel_LowThreatSpawnTables
        elseif threatLevel == "High" then
            tbl = dangerLevel_HighThreatSpawnTables
        elseif threatLevel == "Standard" then
            tbl = dangerLevel_StandardSpawnTables
        end
    end

    if not tbl then
        ESCCUtil.Log(_MethodName, "Could not set tbl - function will likely error on return.", 1)
    end

    for _, lt in pairs(tbl) do
        if lt.Level == dangerLevel then
            ESCCUtil.Log(_MethodName, "Found requested table. Returning value.")
            return lt.Table
        end
    end
end

---Gets a standard table of ships for a wave.
---@param _DangerLevel int Danger level of the wave table you want to get
---@param _WaveShips int Number of ships in the wave.
---@param _ThreatLevel string The threat level of the ships you want to spawn - goes low / standard / high
---@param _Faction boolean Whether these are faction ships or pirate shps. Defaults to false.
---@return table Returns a table of ship names - use for spawn[Ship]ByName, i.e. - { "Pirate", "Pirate", "Outlaw" }
function ESCCUtil.getStandardWave(_DangerLevel, _WaveShips, _ThreatLevel, _Faction)
    local _MethodName = "Get Standard Pirate Wave"
    _ThreatLevel = _ThreatLevel or "Standard"
    _Faction = _Faction or false --This will be used for pirates most of the time.

    ESCCUtil.Log(_MethodName, "Getting wave table for " .. tostring(_WaveShips) .. " at danger level " .. tostring(_DangerLevel) .. " at threat level " .. tostring(_ThreatLevel) .. " _Faction is " .. tostring(_Faction))

    local _SpawnTable = self.getStandardTable(_DangerLevel, _ThreatLevel, _Faction)
    local _EnemyTable = {}
    local _Rgen = self.getRand()

    for _ = 1, _WaveShips do
        table.insert(_EnemyTable, _SpawnTable[_Rgen:getInt(1, #_SpawnTable)])
    end

    return _EnemyTable
end

--endregion

--region #MATHEMATICS

function ESCCUtil.getRand()
    local _MethodName = "Get Random Number Generator"
    ESCCUtil.Log(_MethodName, "Beginning...")

    self.RandomCalled = self.RandomCalled + random():getInt(1, 720)
    return Random(Seed(os.time() + self.RandomCalled))
end

function ESCCUtil.clampToNearest(_Value, _Clamp, _Round)
    _Round = _Round or "Down"
    local _ClampCoefficient = math.floor(_Value / _Clamp)
    if _Round == "Up" then
        _ClampCoefficient = math.ceil(_Value / _Clamp)
    end
    return _ClampCoefficient * _Clamp
end

function ESCCUtil.getDistanceToCenter(_X, _Y)
    local _MethodName = "Get Distance to Center"

    local _Dist = math.sqrt((_X * _X) + (_Y * _Y))

    ESCCUtil.Log(_MethodName, "Distance to center is: " .. _Dist)

    return _Dist
end

function ESCCUtil.getPosOnRing(x_in, y_in, dist)
    --local slope = y_in/x_in
    --local x = dist/math.sqrt(slope^2 + 1)
    --if x_in < 0 then x = -x end
    --local y = slope*x
    --return x, y

    local _Dist1 = math.sqrt((x_in * x_in) + (y_in * y_in))
    local _Pos = vec2(x_in, y_in) * (dist/_Dist1)

    return math.floor(_Pos.x), math.floor(_Pos.y)
end

function ESCCUtil.getVectorAtDistance(_position, _distance, _min)
    local _xrange = { _xmin = _position.x - _distance, _xmax = _position.x + _distance }
    local _yrange = { _ymin = _position.y - _distance, _ymax = _position.y + _distance }
    local _zrange = { _zmin = _position.z - _distance, _zmax = _position.z + _distance }

    local _xrand = random()
    local _rejects = {}

    --for _MIN = true, _distance is the MINIMUM - so we want to be outside of it.
    local _evalForDistance = function(_fdist, _dist)
        if _fdist >= _dist then
            return true
        else
            return false
        end
    end
    --for _MIN = false, _distance is the MAXIMUM, so we want to be inside of it.
    if not _min then
        _evalForDistance = function(_fdist, _dist)
            if _fdist <= _dist then
                return true
            else
                return false
            end
        end
    end

    for _ = 1, 100 do
        local _vecx = _xrand:getFloat(_xrange._xmin, _xrange._xmax)
        local _vecy = _xrand:getFloat(_yrange._ymin, _yrange._ymax)
        local _vecz = _xrand:getFloat(_zrange._zmin, _zrange._zmax)
        local _vec = vec3(_vecx, _vecy, _vecz)

        local _cdistance = distance(_vec, _position)
        if _evalForDistance(_cdistance, _distance) then
            return _vec
        else
            table.insert(_rejects, { _adist = _cdistance, _avec = _vec })
        end
    end

    --If we still haven't found one in 100 tries, fish through the rejects table for the best one.
    local _evalvsdist = 0
    if not _min then
        _evalvsdist = math.huge
    end
    local _tidx = 0
    for idx, _reject in pairs(_rejects) do
        local _set = false
        if _min then
            if _evalvsdist > _reject._adist then
                _set = true
            end
        else
            if _evalvsdist <= _reject._adist then
                _set = true
            end
        end

        if _set then
            _evalvsdist = _reject.adist
            _tidx = idx
        end
    end

    return _rejects[_tidx]._avec
end

--endregion

--region #ENTITIES

function ESCCUtil.countEntitiesByValue(_Value)
    --We know this works, and the spam messages can be quite annoying. There's no need to add debugging to this.
    local _Entities = {Sector():getEntitiesByScriptValue(_Value)}
    if _Entities then
        return #_Entities
    else
        return 0
    end
end

function ESCCUtil.countEntitiesByType(entityType)
    local entities = {Sector():getEntitiesByType(entityType)}
    if entities then
        return #entities
    else
        return 0
    end
end

function ESCCUtil.countEntitiesByValueAndScript(value, script)
    local entities = {Sector():getEntitiesByScriptValue(value)}
    if entities then
        local retValue = 0
        for _, entity in pairs(entities) do
            if entity:hasScript(script) then
                retValue = retValue + 1
            end
        end
        return retValue
    else
        return 0
    end
end

function ESCCUtil.allPiratesDepart()
    local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
    local _Rgen = ESCCUtil.getRand()
    for _, _P in pairs(_Pirates) do
        _P:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(3, 6))
    end
end

function ESCCUtil.allXsotanDepart()
    local _Ships = {Sector():getEntitiesByScriptValue("is_xsotan")}
    local _Rgen = ESCCUtil.getRand()
    for _, _S in pairs(_Ships) do
        _S:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(2, 5))
    end
end

function ESCCUtil.majorEntityTypes()
    --Basically anything that's not loot / wreckages.
    return {
        EntityType.None,
        EntityType.Ship,
        EntityType.Station,
        EntityType.Asteroid,
        EntityType.Torpedo,
        EntityType.Fighter,
        EntityType.Container
    }
end

function ESCCUtil.allEntityTypes()
    return {
        EntityType.None,
        EntityType.Ship,
        EntityType.Drone,
        EntityType.Station,
        EntityType.Turret,
        EntityType.Asteroid,
        EntityType.Wreckage,
        EntityType.Anomaly,
        EntityType.Loot,
        EntityType.WormHole,
        EntityType.Torpedo,
        EntityType.Fighter,
        EntityType.Container,
        EntityType.Unknown,
        EntityType.Other
    }
end

function ESCCUtil.replaceIcon(_Craft, _IconPath)
    local _safetyBreakout = 0
    while _Craft:hasScript("icon.lua") or _safetyBreakout < 10 do --Shouldn't need more than 10 iterations to nuke the old icon script.
        _Craft:removeScript("icon.lua")
        _safetyBreakout = _safetyBreakout + 1
    end

    _Craft:addScript("icon.lua", _IconPath)
end

function ESCCUtil.setBombardier(_Ship)
    local _TitleArgs = _Ship:getTitleArguments()

    local _ToughnessArg = _TitleArgs.toughness or ""
    local _TitleArg = _TitleArgs.title or ""
    local _ScriptNameArg = "Bombardier "

    _Ship:setTitle("${toughness}${scriptname}${title}", {toughness = _ToughnessArg, title = _TitleArg, scriptname = _ScriptNameArg})
    self.replaceIcon(_Ship, "data/textures/icons/pixel/torpedoboatex.png")
end

function ESCCUtil.setDeadshot(_Ship)
    local _TitleArgs = _Ship:getTitleArguments()

    local _ToughnessArg = _TitleArgs.toughness or ""
    local _TitleArg = _TitleArgs.title or ""
    local _ScriptNameArg = "Deadshot "

    _Ship:setTitle("${toughness}${lasername}${title}", {toughness = _ToughnessArg, title = _TitleArg, lasername = _ScriptNameArg})
    self.replaceIcon(_Ship, "data/textures/icons/pixel/laserboat.png")
end

function ESCCUtil.setMarksman(_Ship)
    --Faction ships usually have less elaborate titles.
    local titleArgs = _Ship:getTitleArguments()

    local newTitle = "Marksman " .. _Ship.title
    
    _Ship:setTitle(newTitle, titleArgs)

    self.replaceIcon(_Ship, "data/textures/icons/pixel/laserboat.png")
end

function ESCCUtil.setFusilier(_Ship)
    --Faction ships usually have less elaborate titles.
    local titleArgs = _Ship:getTitleArguments()

    local newTitle = "Fusilier " .. _Ship.title
    
    _Ship:setTitle(newTitle, titleArgs)

    self.replaceIcon(_Ship, "data/textures/icons/pixel/torpedoboatex.png")
end

function ESCCUtil.removeCivilScripts(_Ship)
    _Ship:removeScript("civilship.lua")
    _Ship:removeScript("dialogs/storyhints.lua")
    _Ship:setValue("is_civil", nil)
    _Ship:setValue("npc_chatter", nil)
end

function ESCCUtil.multiplyOverallDurability(entity, multiplier)
    local useMultiplier = multiplier

    local entityShields = Shield(entity)
    if entityShields then
        entityShields.maxDurabilityFactor = (entityShields.maxDurabilityFactor or 1) * useMultiplier
    else
        useMultiplier = useMultiplier * 2
    end

    local entityDurability = Durability(entity)
    if entityDurability then
        entityDurability.maxDurabilityFactor = (entityDurability.maxDurabilityFactor or 1) * useMultiplier
    end
end

function ESCCUtil.getSingleEntityByValue(_sector, scriptValue)
    _sector = _sector or Sector()

    local scriptTbl = { _sector:getEntitiesByScriptValue(scriptValue) }
    return scriptTbl[1]
end

--endregion

--region #FACTION HELPERS

function ESCCUtil.getNeutralSmugglerFaction()
    local name = "Ureth'gul Smugglers"

    local galaxy = Galaxy()
    local faction = galaxy:findFaction(name)
    if faction == nil then
        faction = galaxy:createFaction(name, 175, 0)
        faction.initialRelations = 0
        faction.initialRelationsToPlayer = 0
        faction.staticRelationsToAll = true
        faction.homeSectorUnknown = true
    end

    return faction
end

--endregion

--region #DIALOGUE HELPERS

function ESCCUtil.setTalkerTextColors(table, talker, talkerColor, textColor)
    for _, dx in pairs(table) do
        dx.talker = talker
        dx.textColor = textColor
        dx.talkerColor = talkerColor
    end
end

--endregion

--region #ANIMATION HELPERS (CLIENT ONLY)

function ESCCUtil.drawConstructionLaser(constructingEntity, constructedEntity, magnitudeMultiplier)
    local _sector = Sector()

    if constructingEntity and valid(constructingEntity) and constructedEntity and valid(constructedEntity) then
        local _random = random()
        local dir = _random:getDirection()

        local magnitudeMultiplier = math.max((magnitudeMultiplier or 1), 1) --Needs to be at least 1.

        local minMagnitude = 10 * magnitudeMultiplier
        local maxMagnitude = 25 * magnitudeMultiplier

        local magnitude = _random:getInt(minMagnitude, maxMagnitude)

        local lsr = _sector:createLaser(constructingEntity.translationf, constructedEntity.translationf + (dir * magnitude), ColorRGB(0, 0.1, 1.0), 1)
        lsr.collision = false
        lsr.maxAliveTime = 0.025
    end
end

function ESCCUtil.drawHealingAnimation(healerEntity, healedEntity)
    local _sector = Sector()
 
    if healerEntity and valid(healerEntity) and healedEntity and valid(healedEntity) then
        local healedEntityHull = healedEntity.durability
        local healedEntityMaxHull = healedEntity.maxDurability

        if healedEntityHull < healedEntityMaxHull then
            local cShipPos = healerEntity.translationf
            local sFramePos = healedEntity.translationf
            local beamColor = ColorRGB(0.0, 0.8, 0.5)

            local repairLaser = _sector:createLaser(cShipPos, sFramePos, beamColor, 16)
            repairLaser.maxAliveTime = 1.5
            repairLaser.collision = false

            local direction = random():getDirection()
            _sector:createHyperspaceJumpAnimation(healedEntity, direction, ColorRGB(0.0, 1.0, 0.6), 0.2)
        end
    end
end

--endregion

function ESCCUtil.getStandardTemplateBlacklist()
    local _MethodName = "Get Standard Template Blacklist"
    ESCCUtil.Log(_MethodName, "Beginning...")

    local templateBlacklist = {
        "sectors/asteroidshieldboss",
        "sectors/ancientgates",
        "sectors/containerfield",
        "sectors/cultists",
        "sectors/pirateasteroidfield",
        "sectors/piratefight",
        "sectors/piratestation",
        "sectors/resistancecell",
        "sectors/researchsatellite",
        "sectors/smugglerhideout",
        "sectors/wreckagefield",
        "sectors/xsotanasteroids",
        "sectors/xsotanbreeders",
        "sectors/xsotantransformed"
    }

    return templateBlacklist
end

function ESCCUtil.getIndex(_Table, _Element)
    local _MethodName = "Get Index of Table"
    if not _Table or not _Element then
        ESCCUtil.Log(_MethodName, "Cannot get random element - either the table or the element was not provided", 1)
        return
    end
    for _IDX, _VAL in pairs(_Table) do
        if _VAL == _Element then
            return _IDX
        end
    end
    --Standard C# practice.
    return -1 
end

function ESCCUtil.getSaneColor(_R, _G, _B)
    --For some reason OpenGL does colors by floats which is just wack.
    local _Rfactor = _R / 255
    local _Gfactor = _G / 255
    local _Bfactor = _B / 255

    return ColorRGB(_Rfactor, _Gfactor, _Bfactor)
end

function ESCCUtil.playerBeatStory(_Player)
    if _Player:getValue("story_completed") or _Player:getValue("wormhole_guardian_destroyed") then
        return true
    else
        return false
    end
end

--region #LOGGING

function ESCCUtil.Log(_MethodName, _Msg, _OverrideDebug)
    local _LocalDebug = ESCCUtil._Debug or 0
    if _OverrideDebug == 1 then
        _LocalDebug = 1
    end

    if _LocalDebug == 1 then
        print("[ESCC Utility] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion

return ESCCUtil