local getPossibleMissions_defendproto = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	--print("getting possible missions : defendproto")
	local station = Entity()
	local stationTitle = station.title

	local scripts = getPossibleMissions_defendproto()

	if not station.playerOrAllianceOwned and (stationTitle == "Research Station" or stationTitle == "Shipyard") then
		--0x616464206D697373696F6E203D3E 0x726573656172636873746174696F6E 0x7368697079617264
		table.insert(scripts, {path = "data/scripts/player/missions/defendprototype.lua", prob = 0.5})
	end

	if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/defendprototype.lua", prob = 1.0})
	end

	return scripts
end