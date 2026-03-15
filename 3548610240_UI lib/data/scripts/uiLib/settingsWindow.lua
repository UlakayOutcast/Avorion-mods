package.path = package.path .. ";data/scripts/uiLib/?.lua"
-- namespace SettingsManager
SettingsManager = {}

--todo separate all UI from the server part
local window
local confirm_window
local graphics_scroll
local sound_scroll
local buttons = {}
local sliders = {}
local pending_pages
local key_names
if onClient() then
	pending_pages = include("settingsPages")
	
	key_names = {
	"Unknown",
	"Return",
	"Escape",
	"Backspace",
	"Tab",
	"Space",
--	"Exclaim",
--	"QuoteDBL",
--	"Hash",
--	"Percent",
--	"Dollar",
--	"Apersand",
--	"Quote",
--	"LeftParen",
--	"RightParent",
--	"Asterisk",
--	"Plus",
	"Comma",
	"Minus",
	"Period",
	"Slash",
	"_0",
	"_1",
	"_2",
	"_3",
	"_4",
	"_5",
	"_6",
	"_7",
	"_8",
	"_9",
--	"Colon",
	"Semicolon",
--	"Less",
--	"Equals",
--	"Greater",
--	"Question",
--	"At",
	"LeftBracket",
	"Backslash",
	"RightBrackent",
--	"Caret",
--	"Underscore",
--	"BackQuote",
	"_A",
	"_B",
	"_C",
	"_D",
	"_E",
	"_F",
	"_G",
	"_H",
	"_I",
	"_J",
	"_K",
	"_L",
	"_M",
	"_N",
	"_O",
	"_P",
	"_Q",
	"_R",
	"_S",
	"_T",
	"_U",
	"_V",
	"_W",
	"_X",
	"_Y",
	"_Z",
	"CapsLock",
	"F1",
	"F2",
	"F3",
	"F4",
	"F5",
	"F6",
	"F7",
	"F8",
	"F9",
	"F10",
	"F11",
	"F12",
	"PrintScreen",
	"ScrollLock",
	"Pause",
	"Insert",
	"Home",
	"PageUp",
	"Delete",
	"End",
	"PageDown",
	"Right",
	"Left",
	"Down",
	"Up",
	"NumlockClear",
	"KP_Divide",
	"KP_Multiply",
	"KP_Minus",
	"KP_Plus",
	"KP_Enter",
	"KP_1",
	"KP_2",
	"KP_3",
	"KP_4",
	"KP_5",
	"KP_6",
	"KP_7",
	"KP_8",
	"KP_9",
	"KP_0",
	"KP_Period",
	"Application",
	"Power",
	"KP_Equals",
	"F13",
	"F14",
	"F15",
	"F16",
	"F17",
	"F18",
	"F19",
	"F20",
	"F21",
	"F22",
	"F23",
	"F24",
	"Execute",
	"Help",
	"Menu",
	"Select",
	"Stop",
	"Again",
	"Undo",
	"Cut",
	"Copy",
	"Paste",
	"Find",
	"Mute",
	"VolumeUp",
	"VolumeDown",
	"KP_Comma",
	"KP_EqualsAs400",
	"AltErase",
	"SysReq",
	"Cancel",
	"Clear",
	"Prior",
	"Return2",
	"Separator",
	"Out",
	"Oper",
	"ClearAgain",
	"Crsel",
	"Exsel",
	"ThousandsSeparator",
	"DecimalSeparator",
	"CurrencyUnit",
	"CurrencySubUnit",
	"KP_00",
	"KP_000",
	"KP_LeftParen",
	"KP_RightParen",
	"KP_LeftBrace",
	"KP_RightBrace",
	"KP_Tab",
	"KP_Backspace",
	"KP_A",
	"KP_B",
	"KP_C",
	"KP_D",
	"KP_E",
	"KP_F",
	"KP_Xor",
	"KP_Power",
	"KP_Percent",
	"KP_Less",
	"KP_Greater",
	"KP_Ampersand",
	"KP_DblAmpersand",
	"KP_VerticalBar",
	"KP_DlbVerticalBar",
	"KP_Colon",
	"KP_Hash",
	"KP_Space",
	"KP_At",
	"KP_Exclam",
	"KP_Memstore",
	"KP_Memrecall",
	"KP_Memclear",
	"KP_Memadd",
	"KP_Memsubtract",
	"KP_Memmultiply",
	"KP_Memdivide",
	"KP_PlusMinus",
	"KP_Clear",
	"KP_ClearEntry",
	"KP_Binary",
	"KP_Octal",
	"KP_Decimal",
	"KP_Hexadecimal",
	"LControl",
	"LShift",
	"LAlt",
	"LGui",
	"RControl",
	"RShift",
	"RAlt",
	"RGui",
	"Mode",
	"AudioNext",
	"AudioPrev",
	"AudioStop",
	"AudioPlay",
	"AudioMute",
	"MediaSelect",
	"Www",
	"Mail",
	"Calculator",
	"Computer",
	"AC_Search",
	"AC_Home",
	"AC_Back",
	"AC_Forward",
	"AC_Stop",
	"AC_Refresh",
	"AC_Bookmarks",
	"BrightnessDown",
	"BrightnessUp",
	"DisplaySwitch",
	"KbdIllumToggle",
	"KbdIllumDown",
	"KbdIllumUp",
	"Eject",
	"Sleep",
}
	--(total 235 - 20 invalid)
	for i = 0, 215 do
		local lineName = key_names[(i + 1)]	
		local value = KeyboardKey[lineName]
		key_names[tostring(value)] = lineName
	end
end
local pages = {}
local page_selector

local fixed_resolution
local fixed_position
local size_fix
local can_type = true
local last_clicked_box
local last_clicked_box_text
local confirm_label
local confirm_values

local user_configs = {}

function SettingsManager.getIcon()
	return "data/textures/uiLib/icon.png"
end

function SettingsManager.interactionPossible(player_index)
	local player = Player(player_index)
	local entity = Entity()
	if player.craft.index.value == entity.id.value then
		return true, ""
	else
		return false, ""
	end
end

function SettingsManager.initUI()
	local resolution = getResolution()
	--change size according to the difference with fullHd, keep 16:9 ratio at all costs
	fixed_resolution = vec2(1920*resolution.y/1080, resolution.y)
	fixed_position = vec2((resolution.x - fixed_resolution.x)/2, 0)
	size_fix = fixed_resolution/vec2(1920, 1080)
	
	local menu = ScriptUI()
    window = menu:createWindow(Rect(resolution))

    window.caption = "Mod settings"%_t
    window.showCloseButton = false
    window.moveable = false
	window.consumeAllEvents = true
	window.transparency = 0
	--window.position = fixed_position
    menu:registerWindow(window, "Mod settings"%_t)
	
	local mod_label = window:createLabel(Rect(512*size_fix.y, 32, 1024*size_fix.y, 80*size_fix.y), "Mod" .. ":", 48*size_fix.y)
	
	page_selector = window:createValueComboBox(Rect(vec2(432-128, 96-56)*size_fix), "onSelectPage")
	page_selector.position = vec2(512 + 128, 48)*size_fix.y + fixed_position
	
	local defaults_button = window:createButton(Rect(vec2(256, 96)*size_fix), "Defaults"%_t, "onResetPress")
	defaults_button.position = vec2(512, 944)*size_fix.y + fixed_position
	defaults_button.tooltip = "Reset all settings to default values. Press 'Save' after this to confirm changes"%_t
	
	local save_button = window:createButton(Rect(vec2(512, 96)*size_fix), "Save"%_t, "onSavePress")
	save_button.position = vec2(896, 944)*size_fix.y + fixed_position
	save_button.tooltip = "Save changes by pressing this button or press ESC to undo them"%_t
		
	SettingsManager.createPages()
end

function SettingsManager.createPages()
	for id, config in pairs(pending_pages) do
		local scrollframe = window:createScrollFrame(Rect(vec2(896, 824)*size_fix))
		scrollframe.position = vec2(512, 112)*size_fix.y + fixed_position
		scrollframe:hide()

		pages[id] = {}
		local page = pages[id]
		page.scrollframe = scrollframe
		page.buttons = {}
		page.sliders = {}
		page.keys = {}
		page_selector:addEntry(id, config.name)
		local creator = scrollframe
		
		local last_pos = 0
		for k, line in ipairs(config.lines) do
			local type_ = line.type_
			if type_ == "headline" then
				local label = creator:createLabel(Rect(200*size_fix.y, 0, 712*size_fix.y, 64*size_fix.y), line.text, 40*size_fix.y)
				label.position = label.position + vec2(0, last_pos)
				label:setCenterAligned()

				last_pos = last_pos + 96*size_fix.y
			elseif type_ == "button" then
				local label = creator:createLabel(Rect(90*size_fix.y, 0, 602*size_fix.y, 64*size_fix.y), line.text, 32*size_fix.y)
				label.position = label.position + vec2(0, last_pos)
				if line.tooltip then
					label.tooltip = line.tooltip
				end
				label:setLeftAligned()
				local picture = creator:createPicture(Rect(vec2(128, 64)*size_fix.y), "data/textures/uiLib/switch.png")
				picture.position = label.position + vec2(600, 0)*size_fix.y 
				local button = creator:createButton(Rect(vec2(128, 64)*size_fix.y), "", "onButtonPress")
				button.position = picture.position
				button.hasFrame = false
				
				page.buttons[button.index] = {button = button, config_text = line.config_text, picture = picture, state = "On"}
				last_pos = last_pos + 96*size_fix.y
			elseif type_ == "slider" then
				local label = creator:createLabel(Rect(90*size_fix.y, 0, 384*size_fix.y, 64*size_fix.y), line.text, 32*size_fix.y)
				label.position = label.position + vec2(0, last_pos)
				if line.tooltip then
					label.tooltip = line.tooltip
				end
				label:setLeftAligned()
				
				local slider = creator:createSlider(Rect(vec2(448, 64)*size_fix.y), line.min_, line.max_, line.steps, "", "onSliderMove")
				slider.position = label.position + vec2(304, 0)*size_fix.y
				slider.showScale = false
				
				page.sliders[slider.index] = {slider = slider, config_text = line.config_text, state = 0}
				last_pos = last_pos + 96*size_fix.y
			elseif type_ == "key_select" then
				local label = creator:createLabel(Rect(90*size_fix.y, 0, 384*size_fix.y, 64*size_fix.y), line.text, 32*size_fix.y)
				label.position = label.position + vec2(0, last_pos)
				if line.tooltip then
					label.tooltip = line.tooltip
				end
				label:setLeftAligned()				
				
				local box_1 = creator:createTextBox(Rect(vec2(128, 48)*size_fix.y), "")
				box_1.position = label.position + vec2(432, 8)*size_fix.y
				box_1.frameColor = ColorRGB(0.8, 0.8, 0.8)
				box_1.clearOnClick = true
				
				local plus = creator:createTextField(Rect(vec2(32, 32)*size_fix.y), "+")
				plus.position = box_1.position + vec2(146, 4)*size_fix.y
				plus.padding = 0
				plus.fontSize = 32*size_fix.y
				
				local box_2 = creator:createTextBox(Rect(vec2(128, 48)*size_fix.y), "")
				box_2.position = label.position + vec2(616, 8)*size_fix.y
				box_2.frameColor = ColorRGB(0.8, 0.8, 0.8)
				box_2.clearOnClick = true
				
				page.keys[box_1.index] = {box = box_1, text = line.text, config_text = line.config_text, type_ = 1}
				page.keys[box_2.index] = {box = box_2, text = line.text, config_text = line.config_text, type_ = 2}
				last_pos = last_pos + 96*size_fix.y				
			end
		end
	end
	pages["u3548610240"].scrollframe:show()
	page_selector:setSelectedValueNoCallback("u3548610240")
end

function SettingsManager.onButtonPress(button)
	local page_id = page_selector.selectedValue
	local config = user_configs[page_id]
	local entry = pages[page_id].buttons[button.index]
	if entry.state == "On" then
		entry.state = "Off"
		entry.picture.picture = "data/textures/uiLib/switch_grey_2.png"
		config[entry.config_text] = false
	else
		entry.state = "On"
		entry.picture.picture = "data/textures/uiLib/switch.png"
		config[entry.config_text] = true
	end
end

function SettingsManager.onSliderMove(slider, value)
	local page_id = page_selector.selectedValue
	local config = user_configs[page_id]
	local entry = pages[page_id].sliders[slider.index]
	--onSliderMove triggers even if slider was moved via slider.value = 123, causing errors for slider on other pages
	if not entry then return end
	config[entry.config_text] = value
end

function SettingsManager.formatKeyBox(index, config_text, type_, text, deferred)
	local box = TextBox(index)
	if not box then return end
	if not deferred then
		box.editable = false
		if box.text == "" or box.text == " " then
			if text then
				box.text = text
			end
		end	
		local config = user_configs[page_selector.selectedValue]
		local config_entry = config[config_text]
		config_entry["format_" .. type_] = box.text
		deferredCallback(0.05, "formatKeyBox", index, nil, nil, nil, true)
	else
		can_type = true	
		box.editable = true
	end
end

function SettingsManager.onShowWindow()
	local _, configs = Player():invokeFunction("data/scripts/player/uiLib/UIManager.lua", "sendUserConfig")
	if not configs then 
		print("Error: 'UI lib' user configs failed to load. Default settings will be used")
		displayChatMessage("Error: 'UI lib' user configs failed to load. Default settings will be used. Settings menu cannot be opened until the issue is resolved. Check out steam mod page for more info", "", ChatMessageType.Error)
		window:hide()
		return 
	end
	can_type = true	
	user_configs = configs

	if confirm_window then
		confirm_window:hide()
	end

	for config_id, user_config in pairs(user_configs) do
		local page = pages[config_id]
		if not page then return end
		for _, entry in pairs(page.buttons) do		
			local value = user_config[entry.config_text]
			if value == true then
				entry.state = "On"
				entry.picture.picture = "data/textures/uiLib/switch.png"
			else
				entry.state = "Off"
				entry.picture.picture = "data/textures/uiLib/switch_grey_2.png"
			end
		end
		
		for _, entry in pairs(page.sliders) do		
			local value = user_config[entry.config_text]
			entry.slider.value = value
		end
		
		for _, entry in pairs(page.keys) do		
			local value = user_config[entry.config_text]
			value = value["format_" .. entry.type_]
			if value == "nil" then
				entry.box.text = ""
			else
				entry.box.text = value
			end
		end		
	end
end

function SettingsManager.onSavePress()
	local page_id = page_selector.selectedValue
	local file = io.open("/moddata/UI lib/" .. page_id .. "/user_config.lua", 'w')
	if not file then
		print("UI lib Error: user config is missing")
		displayChatMessage("Error: 'UI lib' user config is missing. Please restart the game to generate a new one", "", ChatMessageType.Error)
		window:hide()
		return
	end
	local user_config = user_configs[page_id]
	if not user_config then return end
	for k, v in pairs(user_config) do
		local value = v
		if type(value) == "table" then
			local str = ""
			str = value.format_1 .. " " .. value.key_1 .. " " .. value.format_2 .. " " .. value.key_2
			value = str
		end
		file:write(k .. " " .. tostring(value) .. '\n')
	end
	io.close(file)
	Player():invokeFunction("data/scripts/player/uiLib/UIManager.lua", "setUserConfig", page_id, user_config)
end

function SettingsManager.onResetPress()
	for config_id, page in pairs(pages) do
		local config_unformatted = pending_pages[config_id].defaults
		local config = {}
		for k, tabl in pairs(config_unformatted) do
			local value = tabl.value
			if type(value) == "table" then
				config[k] = {}
				local config_table = config[k]
				for k_, v_ in pairs(value) do
					config_table[k_] = v_
				end
			else
				config[k] = tabl.value
			end
		end
		for _, entry in pairs(page.buttons) do		
			local value = config[entry.config_text]
			if value == true then
				entry.state = "On"
				entry.picture.picture = "data/textures/uiLib/switch.png"
			else
				entry.state = "Off"
				entry.picture.picture = "data/textures/uiLib/switch_grey_2.png"
			end
		end
		
		for _, entry in pairs(page.sliders) do		
			local value = config[entry.config_text]
			entry.slider.value = value
		end
		
		for _, entry in pairs(page.keys) do		
			local value = config[entry.config_text]
			value = value["format_" .. entry.type_]
			if value == "nil" then
				entry.box.text = ""
			else		
				entry.box.text = value
			end
		end	
		
		user_configs[config_id] = config
	end			
end

function SettingsManager.onSelectPage(selector, id)
	for _, page in pairs(pages) do
		if page.scrollframe.visible then
			page.scrollframe:hide()
			break
		end
	end
	pages[id].scrollframe:show()
end

function SettingsManager.onKeyboardEvent(key, pressed)
	if not window.visible then return end
	if not pressed or not can_type then return end
	local page_id = page_selector.selectedValue		
	local keys = pages[page_id].keys
	if keys then
		for index, tabl in pairs(keys) do
			local box = TextBox(index)
			if box and box.isTypingActive then
				local config = user_configs[page_id]
				local config_entry = config[tabl.config_text]
				if type(config_entry) ~= "table" then print("UI lib Error: wrong default config data for key mapping") return end
				--"Escape" key
				if key == 41 then
					if config_entry["key_" .. tabl.type_] == "nil" then return end
					if not confirm_window then
						confirm_window = window:createWindow(Rect(vec2(768, 256)*size_fix.y))
						confirm_window:center()
						confirm_window.transparency = 0										
						confirm_window.showCloseButton = true
						confirm_window.moveable = false
						confirm_window.consumeAllEvents = true
						confirm_window.shadeBackground = true
						
						confirm_label = confirm_window:createLabel(Rect(10*size_fix.y, 16*size_fix.y, 758*size_fix.y, 64*size_fix.y), "", 18*size_fix.y)
						confirm_label:setCenterAligned()
						local button = confirm_window:createButton(Rect(vec2(370, 64)*size_fix.y), "Yes", "onConfrimYes")
						button.position = button.position + vec2(10, 192)*size_fix.y
						button = confirm_window:createButton(Rect(vec2(370, 64)*size_fix.y), "No", "onConfrimNo")
						button.position = button.position + vec2(388, 192)*size_fix.y
					end
					confirm_window:show()
					confirm_label.caption = "Remove binding of '${key_name}' to '${line_name}'. Are you shure?" % {key_name = config_entry["format_" .. tabl.type_], line_name = tabl.text}
					confirm_values = {box = box, config_entry = config_entry, type_ = tabl.type_}
				else
					--tabl.type_ 1 = key 1 (left) tabl.type_ 2 = key 2 (right)
					config_entry["key_" .. tabl.type_] = key
					can_type = false
					deferredCallback(0.05, "formatKeyBox", index, tabl.config_text, tabl.type_, key_names[(tostring(key))])		
				end
				
				break
			end
		end
	end
end

function SettingsManager.onMouseEvent(key, pressed)
	if not window.visible then return end
	if not pressed then return end
	--[[
	if confirm_window then 
		print(confirm_window.visible)
	end
	--]]
	deferredCallback(0.05, "onBoxClicked")
end

function SettingsManager.onBoxClicked()
	local page_id = page_selector.selectedValue		
	local keys = pages[page_id].keys
	local current_box
	local new_box_text
	if keys then
		for index, tabl in pairs(keys) do
			local box = TextBox(index)
			if box and box.isTypingActive then
				local config = user_configs[page_id]
				local config_entry = config[tabl.config_text]
				if type(config_entry) ~= "table" then print("UI lib Error: wrong default config data for key mapping") return end			
				new_box_text = config_entry["format_" .. tabl.type_]
				if new_box_text == "nil" then
					new_box_text = ""
				end
				current_box = box
				break
			end
		end
	end
	
	if last_clicked_box_text then
		if current_box then
			if last_clicked_box then
				if last_clicked_box.index ~= current_box.index then
					if last_clicked_box.text == "" then
						last_clicked_box.text = last_clicked_box_text
					end
				end
			end
		else
			if last_clicked_box then
				if last_clicked_box.text == "" then
					last_clicked_box.text = last_clicked_box_text
				end
			end
		end
	end
	last_clicked_box_text = new_box_text
	last_clicked_box = current_box
end

function SettingsManager.onConfrimYes()
	confirm_values.config_entry["format_" .. confirm_values.type_] = "nil"
	confirm_values.config_entry["key_" .. confirm_values.type_] = "nil"
	last_clicked_box_text = nil
	last_clicked_box = nil
	confirm_values.box.text = ""
	
	confirm_window:hide()
end

function SettingsManager.onConfrimNo()
	confirm_window:hide()
end