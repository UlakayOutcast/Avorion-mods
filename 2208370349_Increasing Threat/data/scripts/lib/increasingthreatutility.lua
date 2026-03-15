package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("faction")

local _LGDist = 250 --_#DistADj
local _XLGDist = 300 --Give room for Pillagers to move.
local _XXLGDist = 350 --Give room for the Devastator to move.

--General rule of thumb -- "shipTable" gives a list of ships to spawn. spawnTable gives a list of ships that it is possible to spawn.
local pirate_attackTypes = {
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 15, reward = 1.0, strength = 3.5, shipTable = {"Pirate", "Bandit", "Bandit"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 25, reward = 1.5, strength = 4.5, shipTable = {"Pirate", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 35, reward = 1.5, strength = 4.5, shipTable = {"Bandit", "Bandit", "Bandit", "Outlaw", "Outlaw"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 45, reward = 2.0, strength = 6, shipTable = {"Raider", "Bandit", "Bandit"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 10, maxChallenge = 55, reward = 2.0, strength = 7.5, shipTable = {"Pirate", "Pirate", "Pirate", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 20, maxChallenge = 65, reward = 2.5, strength = 7.5, shipTable = {"Raider", "Bandit", "Bandit", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 30, maxChallenge = 75, reward = 2.5, strength = 9, shipTable = {"Raider", "Bandit", "Bandit", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 40, maxChallenge = 85, reward = 3.0, strength = 10.5, shipTable = {"Raider", "Raider", "Bandit", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 50, maxChallenge = 95, reward = 3.0, strength = 10.5, shipTable = {"Ravager", "Bandit", "Pirate"}}, --end of +0.5 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 60, maxChallenge = 105, reward = 3.35, strength = 12, shipTable = {"Raider", "Marauder", "Disruptor", "Marauder", "Marauder"}}, --start of +0.35 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 70, maxChallenge = 115, reward = 3.35, strength = 12, shipTable = {"Ravager", "Marauder", "Disruptor"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 80, maxChallenge = 125, reward = 3.7, strength = 14, shipTable = {"Prowler", "Bandit", "Bandit"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 90, maxChallenge = 135, reward = 3.7, strength = 16, shipTable = {"Raider", "Raider", "Raider", "Marauder", "Marauder"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 100, maxChallenge = 150, reward = 4.05, strength = 16, shipTable = {"Prowler", "Marauder", "Disruptor"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 120, maxChallenge = 170, reward = 4.05, strength = 18, shipTable = {"Prowler", "Pirate", "Pirate", "Pirate", "Pirate"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 140, maxChallenge = 190, reward = 4.4, strength = 20, shipTable = {"Prowler", "Marauder", "Disruptor", "Marauder", "Marauder"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 160, maxChallenge = 210, reward = 4.4, strength = 20, shipTable = {"Ravager", "Ravager", "Marauder", "Marauder"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 180, maxChallenge = 230, reward = 4.75, strength = 22, shipTable = {"Prowler", "Ravager", "Bandit", "Bandit"}, dist = _LGDist}, --end of +0.35 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 200, maxChallenge = 240, reward = 4.95, strength = 24, shipTable = {"Pillager", "Disruptor", "Marauder", "Marauder"}, dist = _XLGDist}, --start of +0.2 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 220, maxChallenge = 250, reward = 4.95, strength = 26, shipTable = {"Pillager", "Disruptor", "Marauder", "Raider"}, dist = _XLGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 240, maxChallenge = 260, reward = 5.15, strength = 26, shipTable = {"Prowler", "Prowler", "Bandit", "Bandit"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 260, maxChallenge = -1, reward = 5.15, strength = 28, shipTable = {"Pillager", "Ravager", "Raider"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 280, maxChallenge = -1, reward = 5.35, strength = 30, shipTable = {"Ravager", "Ravager", "Ravager", "Disruptor", "Raider"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 300, maxChallenge = -1, reward = 5.35, strength = 30, shipTable = {"Prowler", "Prowler", "Marauder", "Marauder", "Marauder"}, dist = _LGDist},
    {minHatred = 0, minNotoriety = 0, minChallenge = 320, maxChallenge = -1, reward = 5.55, strength = 32, shipTable = {"Devastator", "Marauder", "Disruptor"}, dist = _XXLGDist}
}
--Lower levels are now applicable b/c of background attacks + entity attacks
local hatred_attackTypes = {
    { maxHatred = 100, spawnTable = { "Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder" } },
    { maxHatred = 200, spawnTable = { "Outlaw", "Bandit", "Bandit", "Pirate", "Pirate", "Marauder", "Marauder", "Marauder", "Raider", "Raider" } },
    { maxHatred = 300, spawnTable = { "Bandit", "Pirate", "Pirate", "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Raider", "Ravager" } },
    { maxHatred = 400, spawnTable = { "Marauder", "Marauder", "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Raider", "Ravager", "Ravager" } },
    { maxHatred = 500, spawnTable = { "Marauder", "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Raider", "Ravager", "Ravager", "Ravager" } },
    { maxHatred = 600, spawnTable = { "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Scorcher", "Ravager", "Ravager", "Ravager", "Ravager" } },
    { maxHatred = 700, spawnTable = { "Disruptor", "Disruptor", "Raider", "Raider", "Scorcher", "Scorcher", "Ravager", "Ravager", "Prowler", "Prowler" } },
    { maxHatred = 800, spawnTable = { "Disruptor", "Raider", "Scorcher", "Scorcher", "Ravager", "Ravager", "Prowler", "Prowler", "Prowler", "Pillager" } },
    { maxHatred = 900, spawnTable = { "Scorcher", "Scorcher", "Scorcher", "Ravager", "Ravager", "Ravager", "Prowler", "Prowler", "Pillager", "Devastator" } },
    { maxHatred = 1000, spawnTable = { "Scorcher", "Scorcher", "Scorcher", "Ravager", "Ravager", "Prowler", "Prowler", "Pillager", "Pillager", "Devastator" } },
    { maxHatred = 1100, spawnTable = { "Scorcher", "Scorcher", "Scorcher", "Ravager", "Prowler", "Prowler", "Pillager", "Pillager", "Devastator", "Devastator" } },
    { maxHatred = -1, spawnTable = { "Scorcher", "Scorcher", "Prowler", "Prowler", "Pillager", "Pillager", "Pillager", "Devastator", "Devastator", "Devastator" } }
}
local notoriety_attackTypes = {
    { maxNotoriety = 50, spawnTable = {"Marauder", "Disruptor", "Disruptor", "Pirate", "Pirate", "Pirate", "Bandit", "Bandit", "Bandit", "Bandit"}},
    { maxNotoriety = 100, spawnTable = {"Marauder", "Marauder", "Disruptor", "Disruptor", "Pirate", "Pirate", "Pirate", "Bandit", "Bandit", "Bandit"}},
    { maxNotoriety = 150, spawnTable = {"Marauder", "Marauder", "Marauder", "Disruptor", "Disruptor", "Disruptor", "Pirate", "Pirate", "Pirate", "Bandit"}},
    { maxNotoriety = -1, spawnTable = {"Raider", "Raider", "Marauder", "Marauder", "Marauder", "Disruptor", "Disruptor", "Disruptor", "Pirate", "Pirate"}}
}
local lowthreat_spawnTables = {
    {spawnTable = {"Outlaw", "Outlaw", "Outlaw", "Bandit", "Bandit", "Pirate"}},
    {spawnTable = {"Outlaw", "Outlaw", "Bandit", "Bandit", "Pirate", "Pirate"}},
    {spawnTable = {"Outlaw", "Bandit", "Bandit", "Pirate", "Pirate", "Marauder"}}
}

local ITUtil = {}

ITUtil._Debug = 0

function ITUtil.getFixedStandardTable(challenge, hatred, notoriety)
    local possible_tables = {}
    for _, at in pairs(pirate_attackTypes) do
        --all conditions have to be met.
        if challenge >= at.minChallenge and (challenge < at.maxChallenge or at.maxChallenge == -1) and hatred >= at.minHatred and notoriety >= at.minNotoriety then
            table.insert(possible_tables, at)
        end
    end

    return possible_tables[math.random(#possible_tables)]
end

function ITUtil.getLowThreatTable()
    local pickedTable = lowthreat_spawnTables[math.random(#lowthreat_spawnTables)]

    return pickedTable.spawnTable
end

function ITUtil.getHatredTable(hatred)
    for _, p in pairs(hatred_attackTypes) do
        if hatred <= p.maxHatred or p.maxHatred == -1 then
            return p.spawnTable
        end
    end
end

function ITUtil.getNotorietyTable(notoriety)
    for _, p in pairs(notoriety_attackTypes) do
        if notoriety <= p.maxNotoriety or p.maxNotoriety == -1 then
            return p.spawnTable
        end
    end
end

function ITUtil.getSectorPlayerValueTable(piratefactionIndex)
    local players = {Sector():getPlayers()}
    local ITPlayers = {}

    for _, p in pairs(players) do
        local hatredindex = "_increasingthreat_hatred_" .. piratefactionIndex
        local xhatred = p:getValue(hatredindex) or 0
        local xnotoriety = p:getValue("_increasingthreat_notoriety") or 0

        table.insert(ITPlayers, {player = p, hatred = xhatred, notoriety = xnotoriety})
    end

    return ITPlayers
end

function ITUtil.getSectorPlayersByHatred(piratefactionIndex)
    local ITPlayers = ITUtil.getSectorPlayerValueTable(piratefactionIndex)
    table.sort(ITPlayers, function(a,b) return a.hatred > b.hatred end)

    return ITPlayers
end

function ITUtil.getSectorPlayersByNotoriety(piratefactionIndex)
    local ITPlayers = ITUtil.getSectorPlayerValueTable(piratefactionIndex)
    table.sort(ITPlayers, function(a,b) return a.notoriety > b.notoriety end)

    return ITPlayers
end

function ITUtil.unpauseEvents()
    local _MethodName = "Unpause Events"
    local _Players = {Sector():getPlayers()}

    for _, _Player in pairs(_Players) do
        ITUtil.Log(_MethodName, "Unpausing events for " .. tostring(_Player.name))
        _Player:invokeFunction("player/background/increasingthreatbackground.lua", "unpauseEvents")
    end
end

function ITUtil.setIncreasingThreatTraits(_Faction)
    local _MethodName = "Set Increasing Threat Traits"
    local pirateTraitsSet = _Faction:getValue("_increasingthreat_traits2_set")
    if not pirateTraitsSet then
        ITUtil.Log(_MethodName, "Pirate traits not set - setting pirate traits.")
        local seed = Server().seed + _Faction.index
        local random = Random(seed)
        local vengeful = random:getFloat(-1.0, 1.0) --Vengeful <==> Craven
        local tempered = random:getFloat(-1.0, 1.0) --Tempered <==> Covetous
        local brutish = random:getFloat(-1.0, 1.0) --Brutish <==> Wily

        SetFactionTrait(_Faction, "vengeful", "craven", vengeful)
        SetFactionTrait(_Faction, "tempered", "covetous", tempered)
        SetFactionTrait(_Faction, "brutish", "wily", brutish)

        _Faction:setValue("_increasingthreat_traits2_set", true)
    end
end

function ITUtil.Log(_MethodName, _Msg)
    if ITUtil._Debug == 1 then
        print("[IT Utility] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

return ITUtil