package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")
include("structuredmission")

mission._Debug = 0
mission._StoryStageValue = "_horizonkeepers_story_stage"

--mission.tracing = true
mission.data.silent = true

--region #GLOBAL PHASE CALLS

--globalphase is set to {} in structuredmission so we don't actually need to reset it here! Neat!
mission.globalPhase.updateInterval = 30 --Update every 30 seconds. As long as we don't set an update interval in the subsequent phaess it should always update every 30 seconds.
mission.globalPhase.updateServer = function()
    local _player = Player()

    --Set mission phase
    if not _player:getValue(mission._StoryStageValue) then
        _player:setValue(mission._StoryStageValue, 1)
    else
        local phaseID = _player:getValue(mission._StoryStageValue)
        setPhase(phaseID)
    end

    --Set side mission values
    if not _player:getValue("_horizonkeepers_last_side1") then
        _player:setValue("_horizonkeepers_last_side1", 0)
    end
    if not _player:getValue("_horizonkeepers_last_side2") then
        _player:setValue("_horizonkeepers_last_side2", 0)
    end
end

mission.globalPhase.onRestore = function()
    local _player = Player()

    if not _player:getValue(mission._StoryStageValue) then
        _player:setValue(mission._StoryStageValue, 1)
    end
end

--endregion

--region #PHASE CALLS

mission.phases[1] = {}
mission.phases[1].onSectorEntered = function(x, y)
    local _MethodName = "Phase 1 On Sector Entered"
    mission.Log(_MethodName, "Running.")

    if onClient() then --We don't care about this on client.
        return
    end

    kothQuestUtil_addMissionToStation(x, y, "data/scripts/player/missions/horizon/horizonstory1.lua")
end

mission.phases[2] = {}
mission.phases[2].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory2.lua"
    local stageReq = 2
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[3] = {}
mission.phases[3].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory3.lua"
    local stageReq = 3
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[4] = {}
mission.phases[4].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory4.lua"
    local stageReq = 4
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[5] = {}
mission.phases[5].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory5.lua"
    local stageReq = 5
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[6] = {}
mission.phases[6].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory6.lua"
    local stageReq = 6
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[7] = {}
mission.phases[7].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory7.lua"
    local stageReq = 7
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[8] = {}
mission.phases[8].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory8.lua"
    local stageReq = 8
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[9] = {}
mission.phases[9].updateServer = function()
    local _player = Player()
    local scriptPath = "data/scripts/player/missions/horizon/horizonstory9.lua"
    local stageReq = 9
    local x, y = Sector():getCoordinates()

    local horizonStage = _player:getValue(mission._StoryStageValue)
    if horizonStage and horizonStage == stageReq and kothQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[10] = {}
mission.phases[10].onSectorEntered = function(x, y)
    local methodName = "Phase 10 On Sector Entered"
    mission.Log(methodName, "Running.")

    if onClient() then --We don't care about this on client.
        return
    end

    local _player = Player()

    --first, check to see if we even do this. First, we need to make sure that it has been at least 30 minutes since we last added the side mission.
    local nextValidSide1Time = (_player:getValue("_horizonkeepers_last_side1") or 0) + (30 * 60)
    local nextValidSide2Time = (_player:getValue("_horizonkeepers_last_side2") or 0) + (30 * 60)

    local currentTime = Server().unpausedRuntime
    local _random = random()

    --These already check if the distance is OK, so no need to check distance in here.
    if currentTime >= nextValidSide1Time and _random:test(0.10) then
        mission.Log(methodName, "Adding side 1 to board.")
        kothQuestUtil_addMissionToStation(x, y, "data/scripts/player/missions/horizon/horizonside1.lua")
    end
    if currentTime >= nextValidSide2Time and _random:test(0.10) then
        mission.Log(methodName, "Adding side 2 to board.")
        kothQuestUtil_addMissionToStation(x, y, "data/scripts/player/missions/horizon/horizonside2.lua")
    end
end

--endregion

--region #SERVER CALLS

function kothQuestUtil_checkDistanceOK(x, y)
    local methodName = "Check Distance OK"

    local dist = math.sqrt(x*x + y*y)
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    local maxDist = Balancing_GetBlockRingMax() + 25

    mission.Log(methodName, "Max Distance is " .. tostring(maxDist))

    if dist <= maxDist and not insideBarrier then
        mission.Log(methodName, "Distance is " .. tostring(dist) .. " and sector inside barrier is " .. tostring(insideBarrier) .. " - this qualifies")
        return true
    else
        mission.Log(methodName, "Distance is " .. tostring(dist) .. " and sector inside barrier is " .. tostring(insideBarrier) .. " which does not qualify")
        return false
    end
end

function kothQuestUtil_addMissionToStation(x, y, missionScript)
    local methodName = "Add Mission To Station"

    if kothQuestUtil_checkDistanceOK(x, y) then
        local stationCandidates = {Sector():getEntitiesByType(EntityType.Station)}
        local stations = {}
        for _, _Station in pairs(stationCandidates) do
            if not _Station.playerOrAllianceOwned and checkCampaignStationOK(_Station.title) then
                table.insert(stations, _Station)
            end
        end

        if #stations > 0 then
            for _, _Station in pairs(stations) do
                local _ok, _bulletin = run(missionScript, "getBulletin", _Station)
                _Station:invokeFunction("bulletinboard", "removeBulletin", _bulletin.brief)
            end

            shuffle(random(), stations)
            stations[1]:invokeFunction("bulletinboard", "addMission", missionScript)
        else
            mission.Log(methodName, "No viable stations from the list of candidates.")
        end
    end
end

--endregion