local ITUtil = include("increasingthreatutility")

WaveUtility._Debug = 0

local IncreasingThreat_createPirateBossWave = WaveUtility.createPirateBossWave
function WaveUtility.createPirateBossWave(callback)
    local _MethodName = "Create Pirate Wave"
    --First, just make the normal wave.
    IncreasingThreat_createPirateBossWave(callback)

    WaveUtility.Log(_MethodName, "Final wave spawning.")
    --Get the most hated player in the sector.
    --Get the table for that player.
    --Spawn 5 pirates. Unfortunately our wily / brutish traits won't work here due to being unable to chain callbacks.
    local generator = AsyncPirateGenerator(nil, callback)
    local _Faction = generator:getPirateFaction()
    local _HatedPlayers = ITUtil.getSectorPlayersByHatred(_Faction.index)
    local _Hatred = _HatedPlayers[1].hatred

    if _Hatred > 500 then
        local _PctChance = math.min(math.ceil(_Hatred / 10), 50)
        local _Roll = random():getInt(0, 100)
        if _Roll < _PctChance then
            WaveUtility.Log(_MethodName, tostring(_Roll) .. " lower than " .. tostring(_PctChance) .. " - adding IT wave.")
            local _SpawnTable = ITUtil.getHatredTable(_Hatred)
            local _Positions = generator:getStandardPositions(5, 350) --_#DistAdj
            local _Positionctr = 1

            generator:startBatch()
            for idx = 1, 5 do
                generator:createScaledPirateByName(randomEntry(_SpawnTable), _Positions[_Positionctr])
                _Positionctr = _Positionctr + 1
            end
            generator:endBatch()
        else
            WaveUtility.Log(_MethodName, tostring(_Roll) .. " higher than " .. tostring(_PctChance) .. " - not adding wave.")
        end
    end   
end

function WaveUtility.Log(_MethodName, _Msg, _OverrideDebug)
    local _LocalDebug = WaveUtility._Debug
    if _OverrideDebug == 1 then
        _LocalDebug = 1
    end

    if _LocalDebug == 1 then
        print("[Wave Utility] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end