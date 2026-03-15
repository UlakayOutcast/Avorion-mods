if onServer() then
	local entity = Entity()
	if entity.isStation then
		if entity.playerOrAllianceOwned then
			entity:addScriptOnce("data/scripts/sellStations/sell.lua")
		end
	end
end
