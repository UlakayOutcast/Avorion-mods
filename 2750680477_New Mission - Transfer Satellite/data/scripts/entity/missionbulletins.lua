local TransferSatellite_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = TransferSatellite_getPossibleMissions()

    --Don't add this mission to player / alliance stations since this actually makes a unit similar to the energy suppression satellite. 
	--We don't want to clutter the player's fleet with this.
	if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/transfersatellite.lua", prob = 2})
	end

    if not station.playerOrAllianceOwned and stationTitle == "Research Station" then
		--0x616464206D697373696F6E203D3E 0x726573656172636873746174696F6E
		table.insert(scripts, {path = "data/scripts/player/missions/transfersatellite.lua", prob = 3})
	end

	return scripts
end