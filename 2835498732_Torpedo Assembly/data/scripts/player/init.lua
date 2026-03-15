if onServer() then
	local player = Player()
	if player then
		--[[
		if player:hasScript("lib/torpedo_assembly.lua") then
			player:removeScript('lib/torpedo_assembly.lua')
		end
		]]
		if not player:hasScript("lib/torpedo_assembly.lua") then
			player:addScript('lib/torpedo_assembly.lua')
		end
	end
end