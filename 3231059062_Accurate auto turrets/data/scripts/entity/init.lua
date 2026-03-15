if onServer() then
    local entity = Entity()
    if entity.playerOrAllianceOwned and entity.isShip then
        entity:addScriptOnce("accurateautoturrets.lua")
    end
end