local Annihilatorium_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = Annihilatorium_getPossibleMissions()

	if not station.playerOrAllianceOwned and (stationTitle == "Smuggler Hideout" or stationTitle == "Smuggler's Market" or stationTitle == "Casino") then
		--0x616464206D697373696F6E203D3E 0x736D7567676C65726F7574706F7374 0x636173696E6F
		table.insert(scripts, {path = "data/scripts/player/missions/annihilatorium.lua", prob = 1})
	end

	return scripts
end