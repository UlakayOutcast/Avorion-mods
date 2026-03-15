local AttackResearchBase_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title
	
	local scripts = AttackResearchBase_getPossibleMissions()

    --Don't add this mission to player / alliance stations.
	if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/attackresearchbase.lua", prob = 2})
	end

	return scripts
end