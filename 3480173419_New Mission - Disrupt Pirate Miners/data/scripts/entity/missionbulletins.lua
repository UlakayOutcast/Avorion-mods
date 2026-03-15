local DisruptPirateMiners_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = DisruptPirateMiners_getPossibleMissions()

	if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/disruptpirateminers.lua", prob = 2.0})
	end
    
    if not station.playerOrAllianceOwned and stationTitle == "Resource Depot" then
		--0x616464206D697373696F6E203D3E 0x7265736F757263656465706F74
		table.insert(scripts, {path = "data/scripts/player/missions/disruptpirateminers.lua", prob = 3.0})
	end

	return scripts
end