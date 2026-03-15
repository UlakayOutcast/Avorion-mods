local expandOperations_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
    local station = Entity()
    local stationTitle = station.title

    local scripts = expandOperations_getPossibleMissions()

    local sectorDevelopmentValue = Sector():getValue("smuggler_development_index")
    local canAdd = false
    if not sectorDevelopmentValue or sectorDevelopmentValue < 5 then
        canAdd = true
    end

    if not station.playerOrAllianceOwned and (stationTitle == "Smuggler Hideout" or stationTitle == "Smuggler's Market") and canAdd then
		table.insert(scripts, {path = "data/scripts/player/missions/expandoperations.lua", prob = 1})
	end

    return scripts
end