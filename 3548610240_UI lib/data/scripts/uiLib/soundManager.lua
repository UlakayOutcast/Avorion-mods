package.path = package.path .. ";data/scripts/uiLib/?.lua"
--soundmanager script is already a mandatory, no need to attach another small one to the player
include("config_manager")

-- namespace SoundManager
SoundManager = {}
local queue = {}
local next_sound
local last_sound
local sound_end_time = 0

function SoundManager.sendUserConfig()
	return ConfigManager_sendUserConfig()
end

function SoundManager.initialize()
	if onClient() then
		Player():registerCallback("addAssistantEntry", "addAssistantEntry")

	end
end

function SoundManager.addAssistantEntry(duration, path, type_, volume)
	if not next(queue) then
		queue[1] = {duration = duration, path = path, type_ = type_, volume = volume}
		next_sound = 1
		last_sound = 1
	else
		last_sound = last_sound + 1 
		queue[last_sound] = {duration = duration, path = path, type_ = type_, volume = volume}		
	end
	if sound_end_time < os.clock() then
		sound_end_time = 0
	end	
end

function SoundManager.updateClient()
	if next(queue) and (sound_end_time < os.clock()) then
		print(sound_end_time, os.clock())
		local sound = queue[next_sound]
		playSound(sound.path, sound.type_, sound.volume)
		sound_end_time = sound.duration + os.clock()
		print(sound_end_time, os.clock())
		queue[next_sound] = nil
		next_sound = next_sound + 1
	end
	
					--	local c, a = Player():invokeFunction("data/scripts/player/uiLib/soundManager.lua", "fonfig")
		--print(c, type(a))
		print(Player():hasScript("data/scripts/player/uiLib/soundManager.lua"))
end
