local SquadOrdersHandling = {}
function SquadOrdersHandling.onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId, assignedFighters, setFighterMoveOrder)
    local factionIndex = Entity(entityIndex).factionIndex
    if assignedFighters[factionIndex] == nil then return end
    local fc = FighterController(entityIndex)
    local deployedFighters = {fc:getDeployedFighters(squadIndex)}
    if orders ~= FighterOrders.Return then
        for _, v in pairs(deployedFighters) do
            if assignedFighters[factionIndex][tostring(v.index)] ~= nil then
                setFighterMoveOrder(v.index, assignedFighters[factionIndex][tostring(v.index)], true, true)
            end
        end
    end
end
return SquadOrdersHandling
