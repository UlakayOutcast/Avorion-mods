local ScrapDelivery_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = ScrapDelivery_getPossibleMissions()

    if not station.playerOrAllianceOwned and stationTitle == "Scrapyard" then
		--0x616464206D697373696F6E203D3E 0x736372617079617264
		table.insert(scripts, {path = "data/scripts/player/missions/scrapdelivery.lua", prob = 15})
	end

	return scripts
end