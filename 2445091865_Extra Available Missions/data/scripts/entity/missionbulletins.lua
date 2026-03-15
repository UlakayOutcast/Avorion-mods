local _Debug = 0

if onServer() then

    --Reset this to be every 15 mins instead of every 60 mins.
    local ExtraAvailableMissions_updateBulletins = MissionBulletins.updateBulletins
    function MissionBulletins.updateBulletins(timeStep)
        --Trick the function into updating 4x faster by passing in 4x the timestep.
        ExtraAvailableMissions_updateBulletins(timeStep * 4)
    end

    local ExtraAvailableMissions_addOrRemoveMissionBulletin = MissionBulletins.addOrRemoveMissionBulletin --Replaces this. Bye!
    function MissionBulletins.addOrRemoveMissionBulletin()
        if _Debug == 1 then
            print("Running new addOrRemoveMissionBulletin function.")
        end
        local scripts = MissionBulletins.getPossibleMissions()
        if #scripts == 0 then return end

        local ostime = Server().unpausedRuntime
        local r = MissionBulletins.random()

        local _MissionCount = r:getInt(0, 5)
        if _MissionCount > 0 then
            for idx = 1, _MissionCount do
                if _Debug == 1 then
                    print("Getting script")
                end
                local scriptPath = MissionBulletins.getWeightedRandomEntry(scripts)
                local ok, bulletin = run(scriptPath, "getBulletin", Entity())

                if _Debug == 1 then
                    print("Script path is : " .. scriptPath)
                end

                if scriptPath == "data/scripts/player/missions/receivecaptainmission.lua" and r:test(0.5) then
                    if _Debug == 1 then
                        print("Removing captain mission from candidacy.")
                    end
                    ok = -1
                end

                if ok == 0 and bulletin then
                    bulletin["TimeAdded"] = ostime
                    Entity():invokeFunction("bulletinboard", "postBulletin", bulletin)
                end
            end
        end

        Entity():invokeFunction("bulletinboard", "checkRemoveBulletins", ostime, r)
    end

end