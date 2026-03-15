	local entity = Entity()
	if entity.isDrone or entity.isShip or entity.isStation and not entity.aiOwned then
		if entity.allianceOwned or entity.playerOwned then
			entity:removeScript("entity/utility/serina.lua")
			entity:addScriptOnce("entity/utility/serina.lua")
		end
	end
