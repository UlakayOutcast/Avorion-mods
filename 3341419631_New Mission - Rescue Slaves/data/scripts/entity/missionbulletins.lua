local RescueSlaves_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title
    
	local scripts = RescueSlaves_getPossibleMissions()

    --Don't add this mission to player / alliance stations.
	if not station.playerOrAllianceOwned and stationTitle == "Habitat" then
		--0x616464206D697373696F6E203D3E 0x68616269746174
		table.insert(scripts, {path = "data/scripts/player/missions/rescueslaves.lua", prob = 1, minDistToCenter = 25})
	end

    if not station.playerOrAllianceOwned and stationTitle == "Trading Post" then
		--0x616464206D697373696F6E203D3E 0x74726164696E67706F7374
        table.insert(scripts, {path = "data/scripts/player/missions/rescueslaves.lua", prob = 0.5, minDistToCenter = 25})
    end

	return scripts
end