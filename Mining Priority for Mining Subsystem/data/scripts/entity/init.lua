if onServer() then
	local entity = Entity()
	if entity:hasComponent(ComponentType.ShipAI) then --or entity.isDrone then
		entity:addScriptOnce("data/scripts/entity/miningpriority.lua")
	end
end