-- Save the original function
local ecnc_Simulation_finalize_original = Simulation.finalize

-- Override the function
function Simulation.finalize(shipName, skipLeveling)
    if ecnc_Simulation_finalize_original then
        ecnc_Simulation_finalize_original(shipName, skipLeveling)
    end 
	
	local command
    for _, c in pairs(self.commands) do
        if c.shipName == shipName then
            command = c
            break
        end
    end

    if not command then return end
	
    local faction = getParentFaction()
    local entry = ShipDatabaseEntry(faction.index, shipName)
    local hours = command.simInternals.runtime / 3600
    local captain = entry:getCaptain()
    local impact = 0
    
    if captain then
		for _, perk in pairs({captain:getPerks()}) do
			impact= impact + CaptainUtility.getRelationshipPerkImpact(captain, perk)
		end
    end
    
	-- simulation.lua arbitrarily defines Galaxy, making calls to Galaxy() impossible, so caching the local faction must be done through captainUtility.lua
	CaptainUtility.applyLocalRelationshipChange(faction, entry, impact*hours*2)
end
