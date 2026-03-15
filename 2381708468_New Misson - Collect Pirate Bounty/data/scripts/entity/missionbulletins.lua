local CollectPirateBounty_getPossibleMissions = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	--print("getting possible missions")
	local station = Entity()
	local stationTitle = station.title

	local scripts = CollectPirateBounty_getPossibleMissions()

	--Apparently they changed the title of smuggler outposts from 1.3.8 to 2.0 but it doesn't actually matter! This is a pretty version-agnostic change.
	--Unlike other missions, you *can* get this from a player or alliance station.
	if stationTitle == "Military Outpost" or stationTitle == "Smuggler Hideout" or stationTitle == "Smuggler's Market" then
		--0x616464206D697373696F6E203D3E 0x616C6C706C61796572 0x6D696C69746172796F7574706F7374 0x736D7567676C65726F7574706F7374
		table.insert(scripts, {path = "data/scripts/player/missions/piratebounty.lua", prob = 15})
	end

	return scripts
end