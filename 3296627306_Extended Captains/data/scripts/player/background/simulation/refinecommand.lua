
-- Save the original function
local ecnc_RefineCommand_getAreaSize_original = RefineCommand.getAreaSize

-- Override the function
function RefineCommand:getAreaSize(ownerIndex, shipName)
    local pos = {x = 0, y = 0}
    
    if ecnc_RefineCommand_getAreaSize_original then
        pos = ecnc_RefineCommand_getAreaSize_original(self,ownerIndex, shipName)
    end
    
    local entry = ShipDatabaseEntry(ownerIndex, shipName)
    local captain = entry:getCaptain()
    local impact = 0
    
    
    if captain then
		for _, perk in pairs({captain:getPerks()}) do
			impact = impact + CaptainUtility.getAreaPerkImpact(captain, perk)
		end
    end
    
    local newX = pos.x + impact
    local newY = pos.y + impact
    
    return {x = newX, y = newY}
end
