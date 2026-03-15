local Utility = {}

function Utility.addConfigCallback(config_id, target, target_id, script_path, function_name)
	local player = Player()
	if not player then return end
	local err = player:invokeFunction("data/scripts/player/uiLib/UIManager.lua", "addConfigCallback", config_id, target, target_id, script_path, function_name)	
	if err ~= 0 then
		local str = "UI lib Error ${err}: cannot add callback to the function: ${function_name}, script: ${script_path}, config: ${config_id}" % {err = err, function_name = function_name, script_path = script_path, config_id = config_id}
		print(str)
	end
end

function Utility.getConfig(config_id)
	local player = Player()
	if not player then return end
	local err, config = player:invokeFunction("data/scripts/player/uiLib/UIManager.lua", "sendUserConfig", config_id)	
	if err ~= 0 then
		local str = "UI lib Error ${err}: cannot get config: ${config_id}" % {err = err, config_id = config_id}
		print(str)
	end
	return config
end

return Utility