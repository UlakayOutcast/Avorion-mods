if onServer() then

    -- [1.0 Orders and Looping]
    -- Wrap updateServer in check to prevent waiting if refinery not found
    AIRefine._updateServer = AIRefine.updateServer
    function AIRefine.updateServer(timeStep)
        if noRefineryFoundTimer > 0 then
            AIRefine.finalize(true)
            return
        end
        AIRefine._updateServer(timeStep)
    end

end
