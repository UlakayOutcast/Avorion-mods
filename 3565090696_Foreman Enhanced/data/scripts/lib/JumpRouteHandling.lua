local JumpRouteHandling = {}
function JumpRouteHandling.onShipJumpRouteCalculationStarted(entityId, factionData)
    local ship = Entity(entityId)
    if not valid(ship) or not ship.playerOrAllianceOwned then return end
    for factionIndex, fData in pairs(factionData) do
        if fData.salvageStandbyMode then
            fData.salvageStandbyMode = false
        end
    end
end
return JumpRouteHandling
