--do not copy this
local pages = {}
-----
--the id must be unique. NEVER USE PLAIN MOD ID, otherwise the player's save WILL crash. Add 1 letter to avoid that
local id = "u3548610240"
pages[id] = {}
local config = pages[id]

local recommended_m = 40
local recommended_s = 50
local recommended_vi = 100 

config.name = "UI lib"

config.version = "1.1.0"

config.defaults = {
	music_volume = {value = 40, type_ = "integer", range_min = 0, range_max = 100},
	VI_volume = {value = 100, type_ = "integer", range_min = 0, range_max = 100},
	show_recources = {value = false, type_ = "bool"},
	show_top_bar = {value = true, type_ = "bool"},
	sound_volume = {value = 50, type_ = "integer", range_min = 0, range_max = 100},
	always_show_background = {value = false, type_ = "bool"},
}

config.lines = {
	{type_ = "headline", text = "UI lib"},
	{type_ = "button", config_text = "show_top_bar", text = "Show top bar"%_t, tooltip = "Toggle visibility of the top bar with info: docking status, free space in the cargo hold, money"%_t},
	{type_ = "button", config_text = "always_show_background", text = "Always show backgrounds"%_t, tooltip = "Show backgrounds even if you are far from the station or ship that you are interacting with"%_t},
	{type_ = "button", config_text = "show_recources", text = "Show resources"%_t, tooltip = "Toggle visibility of the resource panel at the top left corner. Breaks immersion, I recommend to turn this off"%_t},
	{type_ = "headline", text = "Sound"},	
	{type_ = "slider", config_text = "music_volume", text = "Music"%_t, min_ = 0, max_ = 100, steps = 50, tooltip = "Recommended value"%_t .. ": " .. recommended_m},
	{type_ = "slider", config_text = "sound_volume", text = "Sounds"%_t, min_ = 0, max_ = 100, steps = 50, tooltip = "Recommended value"%_t .. ": " .. recommended_s},
	{type_ = "slider", config_text = "VI_volume", text = "VI"%_t, tooltip = "Recommended value"%_t  .. ": " .. recommended_vi .. ". " .. "Volume of your VI assistant. It comments your interaction with ships and stations (English voice only. If you have means to create a high-quality voiceover for other language, I will gladly include it into this mod, the 'Ui Lib')"%_t, min_ = 0, max_ = 100, steps = 50},
}

--do not copy this
return pages