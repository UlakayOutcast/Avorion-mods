local EscortCivilians_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	local station = Entity()
	local stationTitle = station.title

	local scripts = EscortCivilians_getPossibleMissions()

	if not station.playerOrAllianceOwned and stationTitle == "Military Outpost" then
		--0x616464206D697373696F6E203D3E 0x6D696C69746172796F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/escortcivilians.lua", prob = 2})
	end

    --Slightly more likely to show up @ hq / habitats
    if not station.playerOrAllianceOwned and (stationTitle == "${faction} Headquarters" or stationTitle == "Habitat") then
		--0x616464206D697373696F6E203D3E 0x66616374696F6E6871 0x68616269746174
        table.insert(scripts, {path = "data/scripts/player/missions/escortcivilians.lua", prob = 3})
    end

	return scripts
end