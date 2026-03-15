local EradicateXsotan_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = EradicateXsotan_getPossibleMissions()

	if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/eradicatexsotan.lua", prob = 1, maxDistToCenter = 500})
	end

	if not station.playerOrAllianceOwned and stationTitle == "Resistance Outpost" then
		--0x616464206D697373696F6E203D3E 0x726573697374616E63656F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/eradicatexsotan.lua", prob = 3, maxDistToCenter = 500})
	end

	return scripts
end