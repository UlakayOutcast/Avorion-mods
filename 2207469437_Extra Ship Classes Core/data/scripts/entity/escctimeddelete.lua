package.path = package.path .. ";data/scripts/lib/?.lua"

local _Debug = 0

--Get updates frequently. Shouldn't be an issue.
function getUpdateInterval()
    return 0.5
end

function updateServer(timeStep)
    local _MethodName = "On Update Server"

    local entity = Entity()
    local deletetime = entity:getValue("_escc_deletion_timestamp")
    local servertime = Server().unpausedRuntime

    if deletetime then
        Log(_MethodName, "Deletion time is: " .. tostring(deletetime) .. " server time is: " .. tostring(servertime))
        if servertime > deletetime then
            Log(_MethodName, "Entity deleting self.")
            Sector():deleteEntity(entity)
        end
    end
end

function Log(_MethodName, _Msg)
    if _Debug == 1 then
        print("[ESCC Timed Delete Script] - [" .. _MethodName .. "] - " .. _Msg)
    end
end