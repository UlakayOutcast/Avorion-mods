include ("randomext")

local ITUtil = include("increasingthreatutility")
local IncreasingThreat_backup_spawned = false
local damageUntil_IncreasingThreat_backup = 0

local AsyncPirateGenerator = include("asyncpirategenerator")
local SpawnUtility = include("spawnutility")

local IncreasingThreat_initialize = Backup.initialize
function Backup.initialize()
    IncreasingThreat_initialize()

    if onServer() then
        local _Entity = Entity()
        _Entity:registerCallback("onDestroyed", "onDestroyed")

        damageUntil_IncreasingThreat_backup = _Entity.maxDurability * 0.7
    end
end

local IncreasingThreat_onDamaged = Backup.onDamaged
function Backup.onDamaged(selfIndex, amount, inflictor)
    IncreasingThreat_onDamaged(selfIndex, amount, inflictor)

    if Entity():getValue("_increasingthreat_pirate_shipyard") and not IncreasingThreat_backup_spawned then
        if damageTaken > damageUntil_IncreasingThreat_backup then
            local _Entity = Entity()
            local _Faction = Faction(_Entity.factionIndex)

            if _Faction and _Faction.isAIFaction and not FactionEradicationUtility.isFactionEradicated(_Faction.index) then
                local _Piratect = 4
                local _Brutish = _Faction:getTrait("brutish")
                if _Brutish and _Brutish >= 0.25 then
                    _Piratect = 6
                end

                --Get the most hated player and use them for the purpose of pulling the hatred table.
                local _HatedPlayers = ITUtil.getSectorPlayersByHatred(_Faction.index)
                local _Hatred = _HatedPlayers[1].hatred
                local _SpawnTable = ITUtil.getHatredTable(_Hatred)

                local _Spawns = {}
                for idx = 1, _Piratect do
                    table.insert(_Spawns, randomEntry(_SpawnTable))
                end

                if _Hatred > 500 then
                    table.insert(_Spawns, "Jammer")
                end

                local _Spawnct = #_Spawns

                local _Generator = AsyncPirateGenerator(Backup, Backup.onPirateBackupSpawned)

                _Generator:startBatch()

                local _Positionctr = 1
                local _Positions = _Generator:getStandardPositions(_Spawnct, 350) --_#DistAdj

                for idx = 1, _Spawnct do
                    _Generator:createScaledPirateByName(_Spawns[idx], _Positions[_Positionctr])
                    _Positionctr = _Positionctr + 1
                end

                _Generator:endBatch()

                IncreasingThreat_backup_spawned = true
            end
        end
    end
end

function Backup.onDestroyed()
    if Entity():getValue("_increasingthreat_pirate_shipyard") then
        Sector():sendCallback("onIncreasingThreatPirateShipyardDestroyed")
    end
end

function Backup.onPirateBackupSpawned(_Generated)
    --Get the most hated player and use them for the purpose of pulling the wily trait.
    local _Entity = Entity()
    local _Faction = Faction(_Entity.factionIndex)

    local _HatedPlayers = ITUtil.getSectorPlayersByHatred(_Faction.index)
    local _Hatred = _HatedPlayers[1].hatred
    local _WilyTrait = _Faction:getTrait("wily") or 0

    SpawnUtility.addEnemyBuffs(_Generated)
    SpawnUtility.addITEnemyBuffs(_Generated, _WilyTrait, _Hatred)

    local _Taunts = {
        "This is the end of the line for you!",
        "We're going to kill you!",
        "Hope you're ready to die.",
        "You'll pay for what you did to our friends!",
        "You killed our comrades! Now, we'll kill you!",
        "You're dead! Your pathetic begging won't save you!",
        "We'll tear you to pieces!"
    }
    Sector():broadcastChatMessage(_Generated[1], ChatMessageType.Chatter, randomEntry(_Taunts))
end