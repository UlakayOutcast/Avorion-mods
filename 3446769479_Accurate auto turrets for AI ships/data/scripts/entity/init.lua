if onServer() then
    local entity = Entity()
    if entity.aiOwned and entity.isShip then
        entity:addScriptOnce("accurateautoturretsAI.lua")
    end
end