OALMapCommands = include("ordersandlooping-mapcommands")
OALMapCommands.initialize()

if onClient() then

    -- [1.0 Orders and Looping]
    -- Wrap initUI to update orders and orderButtons
    function MapCommands.initUI()
        -- Run copy of base initUI
        OALMapCommands._initUI()

        -- Extract base orders/missions
        local baseOrders = {}
        for i = #orders, 1, -1 do
            table.insert(baseOrders, table.remove(orders, i))
        end

        -- Insert managed orders
        OALMapCommands.applyCommands(OrderButtonType, orders)

        -- Re-insert base orders/missions, excluding those which are now managed (and those from other mods)
        for i = #baseOrders, 1, -1 do
            if type(baseOrders[i].type) == "string" or baseOrders[i].type > 5 then
                table.insert(orders, table.remove(baseOrders, i))
            end
        end

        -- Re-create order buttons for ship list, filtering disabled missions
        shipList.orderButtons = {}
        for _, order in pairs(orders) do
            if OALMapCommands.commandEnabled(order.type) then
                local button = shipList.ordersContainer:createRoundButton(Rect(), order.icon, order.callback)
                button.tooltip = order.tooltip
                table.insert(shipList.orderButtons, button)
            end
        end
    end

    -- [1.0 Orders and Looping]
    -- Wrap so enchainCoordinates can be set
    function MapCommands.updateOrderButtons()
        OALMapCommands._updateOrderButtons()

        MapCommands.enchainCoordinates = nil

        local cx, cy = GalaxyMap():getSelectedCoordinates()

        local enqueueing = MapCommands.isEnqueueing()
        if #shipList.selectedPortraits > 0 and enqueueing then
            local x, y = MapCommands.getLastLocationFromInfo(shipList.selectedPortraits[1].info)
            if x and y then
                MapCommands.enchainCoordinates = {x=x, y=y}
            else
                MapCommands.enchainCoordinates = {x=cx, y=cy}
            end
        end
    end
	
	-- Сдвигаем панель вверх и в право на 50 пикселей
	barOffset.x = barOffset.x - 50
	barOffset.y = barOffset.y - 50

end

-- [1.0 Orders and Looping]
-- Use OrdersAndLooping order system for default orders to make them configurable
OALMapCommands.addCommand("Patrol", "Patrol Sector"%_t,  "data/textures/icons/back-forth.png",     "onPatrolPressed")
OALMapCommands.addCommand("Attack", "Attack Enemies"%_t, "data/textures/icons/crossed-rifles.png", "onAggressivePressed", true)
OALMapCommands.addCommand("Repair", "Repair"%_t,         "data/textures/icons/health-normal.png",  "onRepairPressed")

-- Insert 1.3.8 commands along with their callbacks
OALMapCommands.addCommand("Mine", "Mine"%_t, "data/textures/icons/mining.png", "onMinePressed")
function MapCommands.onMinePressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addMineOrder")
    if not MapCommands.isEnqueueing() then MapCommands.runOrders() end
end

OALMapCommands.addCommand("RefineOres", "Refine Ores"%_t, "data/textures/icons/metal-bar.png", "onRefineOresPressed")
function MapCommands.onRefineOresPressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addRefineOresOrder")
    if not MapCommands.isEnqueueing() then MapCommands.runOrders() end
end

OALMapCommands.addCommand("Salvage", "Salvage"%_t, "data/textures/icons/scrap-metal.png", "onSalvagePressed")
function MapCommands.onSalvagePressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addSalvageOrder")
    if not MapCommands.isEnqueueing() then MapCommands.runOrders() end
end

OALMapCommands.addCommand("Undo",   "Undo"%_t,           "data/textures/icons/undo.png",           "onUndoPressed")
OALMapCommands.addCommand("Loop", "Loop"%_t, "data/textures/icons/loop.png", "onLoopPressed")
function MapCommands.onLoopPressed()
    if not MapCommands.enchainCoordinates then return end
    MapCommands.enqueueOrder("addLoop", MapCommands.enchainCoordinates.x, MapCommands.enchainCoordinates.y)
end

