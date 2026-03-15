local default_configs = include("settingsPages")

local version = "3.0"

local user_config_latest = {}
--todo*1 check "nil" for conflicts

function ConfigManager_check()
	local file = io.open("/moddata/UI lib/version.lua", 'r')
	if not file then
		print("Missing 'UI lib' folder or 'version.lua' in the 'AppData/Roaming/Avorion/moddata'. Creating...")
		ConfigManager_createFolder()
		local file_ = io.open("/moddata/UI lib/version.lua", 'w')
		file_:write(version)
		io.close(file_)
	else
		print("'UI lib' config file is found. Loading...")
		if file:read() ~= version then
			print("Wrong version of 'UI lib' config detected. Updating...")
			local file_ = io.open("/moddata/UI lib/version.lua", 'w')
			file_:write(version)
			io.close(file_)
		end
		io.close(file)				
	end
	
	for config_id, config in pairs(default_configs) do
		local path = "/moddata/UI lib/" .. config_id .. "/user_config.lua"
		local file = io.open(path, 'r')		
		if not file then
			print("Missing user config for " .. config.name .. ". Creating...")
			createDirectory("moddata/UI lib/" .. config_id)
			local file_ = io.open(path, 'w')
			for name, tabl in pairs(config.defaults) do
				local value = tabl.value
				if tabl.type_ == "key" then
					local str = ""
					str = value.format_1 .. " " .. value.key_1 .. " " .. value.format_2 .. " " .. value.key_2
					value = str
				end
				file_:write(name .. " " .. tostring(value) .. '\n')
			end
			io.close(file_)
			print(config.name .. " config file is created. " .. "Version: " .. config.version)		
		else
			io.close(file)
			ConfigManager_compare(path, config_id, config.name, config.version)		
		end
		user_config_latest[config_id] = ConfigManager_read(config_id)
	end
end

function ConfigManager_createFolder()
	local dir = "moddata"
	--if onServer() then
		--dir = Server().folder.."/"..dir
	--end
	dir = dir .. "/" .. "UI lib"
	createDirectory(dir)
	print("'UI lib' folder is created")
end

function ConfigManager_compare(path, config_id, config_name, version)
	local something_wrong = false
	local old_user_config = ConfigManager_read(config_id)
	--delete old lines that are deprecated now
	local default_config = default_configs[config_id]
	if not default_config then print("UI lib Error: can not check errors in config with id: " .. config_id) return end
	default_config = default_config.defaults
	for k, v in pairs(old_user_config) do 
		if default_config[k] == nil then
			old_user_config[k] = nil
			something_wrong = true
		end
	end		
	--add new lines that are not present in the user config
	for name, tabl in pairs(default_config) do
		local value = old_user_config[name]
		if value == nil then
			old_user_config[name] = tabl.value
			something_wrong = true
		else
			if tabl.type_ == "bool" then
				--value = tostring(value)
				if type(value) ~= "boolean" then
					old_user_config[name] = tabl.value	
					something_wrong = true
				end				
			elseif tabl.type_ == "integer" then
				value = tonumber(value)				
				if not value then
					old_user_config[name] = tabl.value	
					something_wrong = true				
				else
					local _, fractional = math.modf(value)
					if fractional ~= 0 then
						value = math.floor(value)
						something_wrong = true
						if value < tabl.range_min or value > tabl.range_max then
							old_user_config[name] = tabl.value	
							something_wrong = true
						else
							old_user_config[name] = value
						end						
					elseif value < tabl.range_min or value > tabl.range_max then
						old_user_config[name] = tabl.value	
						something_wrong = true
					end
				end
			elseif tabl.type_ == "key" then
				local entry = old_user_config[name]
				local val = value.format_1
				if not val then
					entry.format_1 = tabl.value.format_1
					--print("aaaaa 1")
					something_wrong = true
				end
				val = value.key_1
				if val ~= "nil" then
					val = tonumber(value.key_1)
					if not val then
						entry.key_1 = tabl.value.key_1
						--print("aaaaa 2")	
						something_wrong = true
					else
						local _, fractional = math.modf(val)
						if fractional ~= 0 then
							entry.key_1 = tabl.value.key_1
							--print("aaaaa 3")	
							something_wrong = true
						--elseif val < 1 or val > 216 then
						--arbitraty number, don't know actual limits
						elseif val < 1 or val > 216 then
							entry.key_1 = tabl.value.key_1
							--print("aaaaa 4", entry.key_1)
							something_wrong = true
						end
					end
				end
				val = value.format_2
				if not val then
					entry.format_2 = tabl.value.format_2		
					--print("aaaaa 5")	
					something_wrong = true
				end
				val = value.key_2
				if val ~= "nil" then
					val = tonumber(value.key_2)
					if not val then
						entry.key_2 = tabl.value.key_2
						--print("aaaaa 6")	
						something_wrong = true
					else
						local _, fractional = math.modf(val)
						if fractional ~= 0 then
							entry.key_2 = tabl.value.key_2
							--print("aaaaa 7")
							something_wrong = true
						--elseif val < 1 or val > 216 then
						--arbitraty number, don't know actual limits
						elseif val < 1 or val > 350 then
							entry.key_2 = tabl.value.key_2
							--print("aaaaa 8")
							something_wrong = true
						end
					end
				end
			end
		end
	end

	if something_wrong then
		local file = io.open(path, 'w')
		for k, v in pairs(old_user_config) do
			local value = v
			if type(value) == "table" then
				local str = ""
				str = value.format_1 .. " " .. value.key_1 .. " " .. value.format_2 .. " " .. value.key_2
				value = str
			end
			file:write(k .. " " .. tostring(value) .. '\n')
		end
		io.close(file)	
		print(config_name .. " (" .. config_id .. ") config check is failed: some lines are incorrect. They are replaced with default values. " .. "Version: " .. version)
	else
		print(config_name .. " (" .. config_id .. ") config check is successfull, everything looks normal. " .. "Version: " .. version)
	end
end

function ConfigManager_read(config_id)
	local readConf = {}
	local default_config = default_configs[config_id]
	if not default_config then print("UI lib Error: no can't read config with id: " .. config_id) return end
	default_config = default_config.defaults
	local file = io.open("/moddata/UI lib/" .. config_id .. "/user_config.lua", "r")	
	for line in file:lines() do
		local key
		local entry
		local i = 0
		local tabl
		for word in string.gmatch(line, "%S+") do
			if i == 0 then 
				key = word
				entry = default_config[key]
				i = 1
				if not entry then
					--todo*1 check "nil" for conflicts
					readConf[key] = "nil"
					break
				end
			else
				if i == 1 then
					local type_ = entry.type_
					if type_ == "key" then
						readConf[key] = {format_1 = word}
						tabl = readConf[key]
						i = 2
					else
						if type_ == "integer" then
							readConf[key] = tonumber(word)
						elseif type_ == "bool" then
							if word == "true" then
								readConf[key] = true
							elseif word == "false" then
								readConf[key] = false
							end
						end	
					end
				elseif i == 2 then
					if word ~= "nil" then
						tabl.key_1 = tonumber(word)
					else
						tabl.key_1 = "nil"
					end
					i = 3
				elseif i == 3 then
					tabl.format_2 = word
					i = 4
				elseif i == 4 then
					if word ~= "nil" then
						tabl.key_2 = tonumber(word)
					else
						tabl.key_2 = "nil"
					end
				end
			end
		end
	end

	io.close(file)
	return readConf
end

function ConfigManager_setUserConfig(config_id, data_in)
	user_config_latest[config_id] = data_in
end

function ConfigManager_sendDefaultConfig(config_id)
	local default_config = default_configs[config_id]
	if not default_config then print("UI lib Error: can not invoke sendDefaultConfig() with id: " .. config_id) return end
	default_config = default_config.defaults
	return ConfigManager_copyTable(default_config)
end

function ConfigManager_sendUserConfig(config_id)
	if config_id then
		return ConfigManager_copyTable(user_config_latest[config_id])
	else
		return user_config_latest
	end
end

function ConfigManager_copyTable(tabl)
	if not tabl then return end
	local copy = {}
	--prevent altering of the original table + replace fake nils with actual nils
	for k, v in pairs(tabl) do
		if type(v) == "table" then
			copy[k] = {}
			local tabl = copy[k]
			for key_name, key_value in pairs(v) do
				if key_value ~= "nil" then
					tabl[key_name] = key_value
				end
			end
		else
			copy[k] = v
		end
	end			
	return copy
end

if onClient() then
	ConfigManager_check()
end