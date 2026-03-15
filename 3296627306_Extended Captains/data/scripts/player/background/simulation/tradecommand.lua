-- Save the original function
local ecnc_TradeCommand_getAreaSize_original = TradeCommand.getAreaSize

-- Override the function
function TradeCommand:getAreaSize(ownerIndex, shipName)
    local pos1 = {x = 0, y = 0}
    local pos2 = {x = 0, y = 0}
    local pos3 = {x = 0, y = 0}
    
    if ecnc_TradeCommand_getAreaSize_original then
        pos1, pos2, pos3 = ecnc_TradeCommand_getAreaSize_original(self, ownerIndex, shipName)
    end
    
    local entry = ShipDatabaseEntry(ownerIndex, shipName)
    local captain = entry:getCaptain()
    local impact = 0
    
    if captain then
		for _, perk in pairs({captain:getPerks()}) do
            impact = impact + CaptainUtility.getAreaPerkImpact(captain, perk)
        end
    end
    
    local newX1 = pos1.x + impact
    local newY1 = pos1.y + impact
    local newX2 = pos2.x + impact
    local newY2 = pos2.y + impact
    local newX3 = pos3.x + impact
    local newY3 = pos3.y + impact
    
    return {x = newX1, y = newY1}, {x = newX2, y = newY2}, {x = newX3, y = newY3}
end
