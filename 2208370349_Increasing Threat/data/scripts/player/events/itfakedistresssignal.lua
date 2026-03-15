package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("stringutility")
include ("callable")
include ("galaxy")
include("randomext")

ESCCUtil = include("esccutil")
ESCCBoss = include("esccbossutil")

local PirateGenerator = include ("pirategenerator")
local SectorSpecifics = include ("sectorspecifics")
local SpawnUtility = include ("spawnutility")
local ITUtil = include("increasingthreatutility")

local target = nil
local _Debug = 0

--region #SERVER CALLS
if onServer() then

function initialize(firstInitialization)
    local _MethodName = "Initialize"

    Log(_MethodName, "Initializing Increasing Threat Fake Distress Signal")

    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 7, 12)

    target = nil

    for _, coord in pairs(coords) do

        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, Server().seed)

        if not regular and not offgrid and not blocked and not home then
            target = {x=coord.x, y=coord.y}
            break
        end
    end

    -- if no empty sector could be found, exit silently
    if not target then
        Log(_MethodName, "Could not find a suitable sector. Exiting.")
        ITUtil.unpauseEvents()
        terminate()
        return
    end

    local player = Player()
    player:registerCallback("onSectorEntered", "onSectorEntered")

    if firstInitialization then
        local messages =
        {
            "Mayday! Mayday! We are under attack by pirates! Our position is \\s(%1%:%2%), someone help, please!"%_t,
            "Mayday! CHRRK ... under attack CHRRK ... pirates ... CHRRK ... position \\s(%1%:%2%) ... help!"%_t,
            "Can anybody hear us? We have been ambushed by pirates! Our position is \\s(%1%:%2%) Help!"%_t,
            "This is a distress call! Our position is \\s(%1%:%2%) We are under attack by pirates, please help!"%_t,
            "Help! uh... I'm a rich trader and I'm being attacked by pirates at \\s(%1%:%2%) Help! Help! Reward! Reward!"%_t,
        }

        player:sendChatMessage("Unknown"%_t, 0, messages[random():getInt(1, #messages)], target.x, target.y)
        player:sendChatMessage("", 3, "You have received a distress signal from an unknown source."%_t)
    end

end

function onSectorEntered(player, x, y)
    local _MethodName = "On Sector Entered"

    if x ~= target.x or y ~= target.y then return end

    local pirates = {}
    local _PirateSpawns = {}

    local _PirateFaction = PirateGenerator.getPirateFaction()
    local _HatedPlayers = ITUtil.getSectorPlayersByHatred(_PirateFaction.index)

    local _MostHated = _HatedPlayers[1]
    local _HatredLevel = _MostHated.hatred
    local _BossSpawned = false

    if _HatredLevel <= 500 then
        Log(_MethodName, "Pirates sending standard Avorion Fake Distress Call table.")
        --Up to 500, use the fixed table.
        table.insert(_PirateSpawns, "Marauder")
        table.insert(_PirateSpawns, "Marauder")
        table.insert(_PirateSpawns, "Disruptor")
        table.insert(_PirateSpawns, "Raider")
        table.insert(_PirateSpawns, "Pirate")
        table.insert(_PirateSpawns, "Pirate")
        table.insert(_PirateSpawns, "Bandit")
        table.insert(_PirateSpawns, "Bandit")
        table.insert(_PirateSpawns, "Bandit")
        table.insert(_PirateSpawns, "Bandit")
    else
        Log(_MethodName, "Pirates hate players enough to send a tougher fleet.")
        local _MaxExtraPirates = 10
        local _Denominator = 50
        local _Brutish = _PirateFaction:getTrait("brutish")
        if _Brutish and _Brutish >= 0.25 then
            _MaxExtraPirates = 15
            _Denominator = 33
        end

        local _ExtraHatred = math.max(_HatredLevel - 500, 0)
        local _PirateCount = 9 + math.min(_ExtraHatred / _Denominator, _MaxExtraPirates)
        local _Rgen = ESCCUtil.getRand()

        table.insert(_PirateSpawns, "Jammer")
        if _HatredLevel >= 1000 then
            _PirateCount = _PirateCount - 1 --Add a jammer.
            table.insert(_PirateSpawns, "Jammer")
        end

        Log(_MethodName, "Hatred level is " .. tostring(_HatredLevel) .. " -- sending " .. tostring(_PirateCount) .. " total ships after player.")

        --Boss check.
        if ESCCUtil.playerBeatStory(_MostHated.player) and _HatredLevel >= 800 then
            local MissionUT = include("missionutility")
            if MissionUT.checkSectorInsideBarrier(x, y) then
                Log(_MethodName, "Player has completed story, is in core, and hatred is above 800. Checking for boss cooldown.")
                local _UnpausedRuntime = Server().unpausedRuntime
                local _NextBossEncounterTime = _MostHated.player:getValue("_increasingthreat_next_bossencounter") or 0
                if _NextBossEncounterTime <= _UnpausedRuntime then
                    --Start at 30% @ Hatred 800 - caps at 50% @ Hatred 1200.
                    local _PctChance = 30 + math.min(20, math.max((_HatredLevel - 800), 0) / 16.6)
                    Log(_MethodName, "Player boss cooldown is expired. " .. tostring(_PctChance) .. "% chance to encouter a boss.")

                    if _Rgen:getInt(1, 100) < _PctChance then
                        Log(_MethodName, "Boss encounter is on. Spawn a boss.")
                        _PirateCount = _PirateCount - 1
                        _BossSpawned = true
                        local _BossType = _Rgen:getInt(1, 6)
                        ESCCBoss.spawnESCCBoss(_PirateFaction, _BossType)
                        _MostHated.player:setValue("_increasingthreat_next_bossencounter", _UnpausedRuntime + (_Rgen:getInt(2, 4) * 3600))
                    else
                        Log(_MethodName, "Random chance failed.")
                    end
                else
                    Log(_MethodName, "Encounter on cooldown.")
                end
            else
                Log(_MethodName, "Not inside barrier.")
            end
        else
            Log(_MethodName, "Story was not completed, or hatred was less than 800.")
        end

        local _SpawnTable = ITUtil.getHatredTable(_HatredLevel)
        for _ = 1, _PirateCount do
            table.insert(_PirateSpawns, _SpawnTable[_Rgen:getInt(1, #_SpawnTable)])
        end
    end

    for _, _Ship in pairs(_PirateSpawns) do
        table.insert(pirates, PirateGenerator.createPirateByName(_Ship, PirateGenerator.getGenericPosition()))
    end

    shuffle(random(), pirates)

    if not _BossSpawned then
        Log(_MethodName, "Attaching script to lead ship.")
        pirates[1]:addScript("dialogs/encounters/pirateambushleader.lua")
    end

    -- add enemy buffs
    SpawnUtility.addEnemyBuffs(pirates) --Covered IT Extra Scripts
    local _Wily = _PirateFaction:getTrait("wily") or 0
    SpawnUtility.addITEnemyBuffs(pirates, _Wily, _HatredLevel)

    terminate()
end

function sendCoordinates()
    invokeClientFunction(Player(callingPlayer), "receiveCoordinates", target)
end
callable(nil, "sendCoordinates")

end
--endregion

function abandon()
    if onClient() then
        invokeServerFunction("abandon")
        return
    end
    terminate()
end
callable(nil, "abandon")

--region #CLIENT CALLS
if onClient() then

function initialize()
    invokeServerFunction("sendCoordinates")
    target = {x=0,y=0}
end

function receiveCoordinates(target_in)
    target = target_in
end

function getMissionBrief()
    return "Distress Signal"%_t
end

function getMissionDescription()
    if not target then return "" end
    return "You have received a distress call from an unknown source. Their last reported position was (${xCoord}, ${yCoord})."%_t % {xCoord = target.x, yCoord = target.y}
end

function getMissionLocation()
    if not target then return 0, 0 end
    return target.x, target.y
end

function secure()
    return {dummy = 1}
end

function restore(data)
    terminate()
end

end
--endregion

function Log(_MethodName, _Msg)
    if _Debug == 1 then
        print("[IT Fake Distress Signal] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end
