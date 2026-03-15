local ShipAIStateManager = {}
function ShipAIStateManager.onShipAIStateChanged(entityId, oldState, newState, factionData)
    local ship = Entity(entityId)
    if not valid(ship) or not ship.playerOrAllianceOwned then return end
    
    -- Only handle jump state changes
    if newState == AIState.Jump then
        local hangar = Hangar(ship.id)
        local controller = hangar and FighterController(ship.id) or nil
        if controller and hangar then
            for _, squadIndex in pairs({hangar:getSquads()}) do
                controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
            end
        end
        local fi = ship.factionIndex
        local sd = factionData[fi] and factionData[fi].ships[tostring(ship.index)]
        if sd then 
            sd.isJumping = true 
            if factionData[fi] then
                factionData[fi].salvageStandbyMode = false
                for otherShipIndex, otherShipData in pairs(factionData[fi].ships) do
                    if otherShipIndex ~= tostring(ship.index) then
                        local otherShip = Entity(Uuid(otherShipIndex))
                        if valid(otherShip) then
                            local otherHangar = Hangar(otherShip.id)
                            local otherController = FighterController(otherShip.id)
                            if otherHangar and otherController then
                                for _, squadIndex in pairs({otherHangar:getSquads()}) do
                                    otherController:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif oldState == AIState.Jump and newState ~= AIState.Jump then
        -- Ship finished jumping, clear the jumping flag
        local fi = ship.factionIndex
        local sd = factionData[fi] and factionData[fi].ships[tostring(ship.index)]
        if sd then 
            sd.isJumping = false
        end
    end
end
return ShipAIStateManager
