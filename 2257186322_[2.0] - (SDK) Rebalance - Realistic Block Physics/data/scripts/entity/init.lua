-- This is always the first script that is executed for an entity with the Scripts component

-- Note: This script does not get attached to the Entity
-- Note: This script is called BEFORE any other scripts are initialized
-- Note: This script is called BEFORE any other scripts are added when creating new Entities (like stations)
-- Note: When loading from Database, other scripts attached to the Entity are available through Entity():hasScript() etc.
-- Note: When adding scripts to the entity from here with addScript() or addScriptOnce(),
--       the added scripts will NOT get initialized immediately,
--       their initialization order is not defined,
--       parameters passed in addition to the script name will be IGNORED and NOT passed to the script's initialize() function,
--       and the script will instead be treated as if loaded from database, with the _restoring variable set in its initialize() function

if onServer() then

    local e = Entity()

    if e.type == EntityType.Station then
        e:addScriptOnce("data/scripts/entity/SDKDisableSharedBlockHealth.lua")
    end

    if e.type == EntityType.Ship then    
        e:addScriptOnce("data/scripts/entity/SDKDisableSharedBlockHealth.lua")
    end

end