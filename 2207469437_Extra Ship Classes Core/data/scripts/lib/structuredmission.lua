--Extensions to StructuredMission.

--region #SERVER FUNCTIONS

function runFullSectorCleanup(cleanAll)
    local methodName = "Cleanup"

    if cleanAll == nil then --if it's not set, then set it to true. Can't do cleanAll = cleanAll or true b/c that will remove (correct) false values.
        cleanAll = true
    end

    if mission.data.custom.cleanUpSector then
        if atTargetLocation() then
            mission.Log(methodName, "In sector - adding delete entities script.", nil)
    
            --Just in case the mission doesn't include ESCCUtil. Deletes everything that clearMissionAssets would when not deleting everything (true/false)
            local _ESCCUtil = include("esccutil")
            local _EntityTypes = _ESCCUtil.majorEntityTypes()
            if cleanAll then
               _EntityTypes = _ESCCUtil.allEntityTypes()
            end
            
            local _sector = Sector()
            _sector:addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes) --Do not need to invoke as we will presumably be leaving shortly.
            _sector:removeScript("sector/traders.lua")
        else
            mission.Log(methodName, "Not in sector - cleaning remotely.", nil)
    
            local cleanupCode = [[
                package.path = package.path .. ";data/scripts/lib/?.lua"
    
                function cleanSectorRemotely(cleanAll)
                    local _ESCCUtil = include("esccutil")
                    local _EntityTypes = _ESCCUtil.majorEntityTypes()
                    if cleanAll then
                        _EntityTypes = _ESCCUtil.allEntityTypes() 
                    end
    
                    local _sector = Sector()
                    _sector:addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
                    _sector:invokeFunction("deleteentitiesonplayersleft.lua", "updateDeletion") --Need to invoke manually since no players are in sector.
                    _sector:removeScript("sector/traders.lua")
                end
            ]]
    
            local _MX, _MY = mission.data.location.x, mission.data.location.y
            Galaxy():loadSector(_MX, _MY)
            runSectorCode(_MX, _MY, true, cleanupCode, "cleanSectorRemotely", cleanAll)
        end
    end
end

function checkCampaignStationOK(stationTitle)
    local validTitles = {
        "Shipyard",
        "Repair Dock",
        "Equipment Dock",
        "Military Outpost",
        "Resource Depot"
    }

    for idx, val in pairs(validTitles) do
        if val == stationTitle then
            return true
        end
    end

    return false
end

--endregion

--region #CLIENT FUNCTIONS

function startBossCameraAnimation(bossId)
    bossId = Uuid(bossId)
    local camera = Player().cameraPosition
    local startPosition = camera.translation

    local boss = Entity(bossId)
    local direction = normalize(boss.translationf - startPosition)
    local endPosition = boss.translationf - direction * boss.radius

    local path = endPosition - startPosition

    local bossUp = boss.up
    if dot(camera.up, bossUp) < 0 then
        bossUp = -bossUp -- limit the angle of rotation for the camera
    end

    local keyframes = {}
    table.insert(keyframes, CameraKeyFrame(startPosition, startPosition + camera.look * 1000, camera.up, 0))
    table.insert(keyframes, CameraKeyFrame(startPosition, bossId, camera.up, 1))
    table.insert(keyframes, CameraKeyFrame(startPosition + path * 0.8, bossId, bossUp, 1.8))
    table.insert(keyframes, CameraKeyFrame(startPosition + path, bossId, bossUp, 4))

    Player():setCameraKeyFrames(unpack(keyframes))
end

function setGameMusic()
    local methodName = "Set Game Music"

    if onServer() then
        mission.Log(methodName, "Called on Server => Invoking on Client")
        invokeClientFunction(Player(), "setGameMusic")
        return
    end

    mission.Log(methodName, "Called on Client => Resetting music")

    local mus = Music()
    mus.autoPlay = true
    mus:fadeOut(1.5)
end

--NOTE: Don't call this until sector arrival is confirmed or else it does not function properly.
function setCustomMusic(track)
    local methodName = "Set Custom Music"

    if onServer() then
        mission.Log(methodName, "Called on Server => Invoking on Client")
        invokeClientFunction(Player(), "setCustomMusic", track)
        return
    end

    mission.Log(methodName, "Called on Client => Setting music")
    local mus = Music()

    mus.autoPlay = false
    mus:fadeOut(1.5)
    mus:playTrack(track, true, nil)
end

--endregion

--region #CLIENT / SERVER functions

function mission.Log(_MethodName, _Msg, _OverrideDebug)
    local localDebug = mission._Debug
    if _OverrideDebug then
        localDebug = _OverrideDebug
    end
    if localDebug and localDebug == 1 then
        local _Name = mission._Name or mission.title or "Mission"
        print("[" .. _Name .. "] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion