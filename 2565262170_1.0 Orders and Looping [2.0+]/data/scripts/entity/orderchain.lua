-- Make mine, refine, and salvage callable
callable(OrderChain, "addMineOrder")
callable(OrderChain, "addRefineOresOrder")
callable(OrderChain, "addSalvageOrder")

-- Keeping copy of addLoop and activateLoop functions just in case
function OrderChain.addLoop(a, b)
    if onClient() then
        invokeServerFunction("addLoop", a, b)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local loopIndex
    if a and not b then
        -- interpret as action index
        loopIndex = a
    elseif a and b then
        -- interpret as coordinates
        local x, y = a, b
        local cx, cy = Sector():getCoordinates()
        local i = OrderChain.activeOrder
        local chain = OrderChain.chain

        if i == 0 then i = 1 end

        while i > 0 and i <= #chain do
            local current = chain[i]

            if cx == x and cy == y then
                loopIndex = i
                break
            end

            if current.action == OrderType.Jump then
                cx, cy = current.x, current.y
            end

            i = i + 1
        end

        if not loopIndex then
            OrderChain.sendError("Could not find any orders at %1%:%2%!"%_T, x, y)
        end
    end

    if not loopIndex or loopIndex == 0 or loopIndex > #OrderChain.chain then return end

    local order = {action = OrderType.Loop, loopIndex = loopIndex}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addLoop")

function OrderChain.activateLoop(loopIndex)
    if OrderChain.activeOrder == loopIndex then
        -- prevent infinite loops
        return
    end

    OrderChain.activeOrder = loopIndex
    OrderChain.activateOrder()
end

-- Wrap orderCompleted in check that makes sure there isn't any more orders in the queue
if onServer() then

    OrderChain._orderCompleted = OrderChain.orderCompleted
    function OrderChain.orderCompleted()
        if not OrderChain.hasMoreOrders() then
            OrderChain._orderCompleted()
        end
    end

end

-- Fix broken base game order validation that tries to use ids as table keys
function OrderChain.checkOrdersValid()
    for _, order in pairs(OrderChain.chain) do
        local exists = false

        for _, v in pairs(OrderType) do
            if order.action == v then
                exists = true
                break
            end
        end

        if not exists then return false end
    end

    return true
end