local XsotanDreadnought_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	--print("getting possible missions")
	local station = Entity()
	local stationTitle = station.title

	local scripts = XsotanDreadnought_getPossibleMissions()

	if not station.playerOrAllianceOwned and stationTitle == "Research Station" then
		--0x616464206D697373696F6E203D3E 0x726573656172636873746174696F6E
		table.insert(scripts, {path = "data/scripts/player/missions/destroyxsodread.lua", prob = 0.5, maxDistToCenter = 400})
	end

    if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/destroyxsodread.lua", prob = 1, maxDistToCenter = 400})
	end

    if not station.playerOrAllianceOwned and stationTitle == "Resistance Outpost" then
		--0x616464206D697373696F6E203D3E 0x726573697374616E63656F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/destroyxsodread.lua", prob = 3, maxDistToCenter = 400})
    end

	return scripts
end