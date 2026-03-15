if onServer() then
	local entity = Entity()
	if entity.isShip or entity.isStation then
		if entity.playerOrAllianceOwned then
			entity:addScriptOnce("data/scripts/uiLib/settingsWindow.lua")
		end
	end
else
	
end