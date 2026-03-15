-- [1.0 Orders and Looping]
-- Wrap getOrderDescription to insert missing descriptions
MapRoutes._getOrderDescription = MapRoutes.getOrderDescription
function MapRoutes.getOrderDescription(action, i, line)
    MapRoutes._getOrderDescription(action, i, line)

    if action.action == OrderType.Repair then
        line.ltext = "[${i}] Repair"%_t % {i=i}
    end
end