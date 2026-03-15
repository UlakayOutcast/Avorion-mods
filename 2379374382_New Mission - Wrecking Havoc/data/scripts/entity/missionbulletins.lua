local WreckingHavoc_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	--print("getting possible missions")
	local station = Entity()
	local stationTitle = station.title

	local scripts = WreckingHavoc_getPossibleMissions()

	if not station.playerOrAllianceOwned and stationTitle == "Scrapyard" then
		--0x616464206D697373696F6E203D3E 0x736372617079617264
		table.insert(scripts, {path = "data/scripts/player/missions/wreckinghavoc.lua", prob = 15})
	end

	return scripts
end