local player = Player()
if onServer() then
	player:addScriptOnce("data/scripts/player/uiLib/UIManager.lua")
end