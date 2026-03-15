
-- Save the original function
local ecnc_SellCommand_getAreaSize_original = SellCommand.getAreaSize
local ecnc_SellCommand_calculatePrediction_original = SellCommand.calculatePrediction
local ecnc_SellCommand_getAreaSize_original = SellCommand.getAreaSize
local temp_captain=nil

-- Override the function
function SellCommand:calculatePrediction(ownerIndex, shipName, area, config)
	local entry = ShipDatabaseEntry(ownerIndex, shipName)
	temp_captain=entry:getCaptain()
	results=ecnc_SellCommand_calculatePrediction_original(self,ownerIndex, shipName, area, config)
	temp_captain=nil
	return results
end
function SellCommand:getAreaSize(ownerIndex, shipName)
    local pos = {x = 0, y = 0}
    
    if ecnc_SellCommand_getAreaSize_original then
        pos = ecnc_SellCommand_getAreaSize_original(self,ownerIndex, shipName)
    end
    
    local captain=temp_captain
	if temp_captain==nil then
		local entry = ShipDatabaseEntry(ownerIndex, shipName)
		captain = entry:getCaptain()
	end
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
