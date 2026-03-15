local entity = Entity() -- gain access to the entity that's being initialized
if entity.type == EntityType.Ship then
    entity:addScriptOnce("entity/MSN.lua") -- add our own script to the entity
end