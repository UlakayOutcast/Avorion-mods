local entity = Entity()
if entity.playerOrAllianceOwned and (entity.isShip or entity.isStation)  then
    entity:addScriptOnce("entity/fleetstatus.lua")
end