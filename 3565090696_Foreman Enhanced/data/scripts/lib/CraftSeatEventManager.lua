local CraftSeatEventManager = {}

function CraftSeatEventManager.onCraftSeatEntered_client(shipIndex, seat, playerIndex, firstPlayer, ships, shipListEx)
    if Player().craft then
        if Entity(shipIndex).factionIndex == Player().craft.factionIndex then
            if ships[tostring(shipIndex)] == nil then return end
            local rowIndex = ships[tostring(shipIndex)].rowIndex
            shipListEx:setEntry(6, rowIndex, "data/textures/icons/player.png", false, false, ColorRGB(1, 1, 1))
            shipListEx:setEntryTooltip(6, rowIndex, Galaxy():getPlayerNames()[playerIndex])
            shipListEx:setEntryType(6, rowIndex, ListBoxEntryType.Icon)
        end
    end
end

function CraftSeatEventManager.onCraftSeatLeft_client(shipIndex, seat, playerIndex, playersRemaining, ships, shipListEx)
    if Entity(shipIndex).factionIndex == Player().craft.factionIndex and playersRemaining == false then
        if ships[tostring(shipIndex)] == nil then return end
        local rowIndex = ships[tostring(shipIndex)].rowIndex
        shipListEx:setEntry(6, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(1, 1, 1))
        shipListEx:setEntryType(6, rowIndex, ListBoxEntryType.Icon)
    end
end
return CraftSeatEventManager
