local TheDig_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = TheDig_getPossibleMissions()

    if not station.playerOrAllianceOwned and stationTitle == "Склад ресурсов" then
		--0x616464206D697373696F6E203D3E 0x7265736F757263656465706F74
		table.insert(scripts, {path = "data/scripts/player/missions/thedig.lua", prob = 3})
	end

	return scripts
end