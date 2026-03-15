package.path = package.path .. ";data/scripts/lib/?.lua"
ShipValidation = include("ShipValidation")
ShipStatusManager = include("ShipStatusManager")
ShipListManager = {}
function ShipListManager.tryAddShipToList(shipId, ships, shipListEx, shipUuidToRow)
    if ships[tostring(shipId)] ~= nil then return end
    local ship = Entity(shipId)
    ships[tostring(shipId)] = { index = ship.id, idStr = ship.id.string, name = ship.name, rowIndex = 0}
    local sortedShips = {}
    for _, v in pairs(ships) do
        table.insert(sortedShips, { name = v.name, index = v.index })
    end
    table.sort(sortedShips, function(a,b) return a.name:upper() < b.name:upper() end)
    shipListEx:clear()
    shipUuidToRow = {}
    for _, v in pairs(sortedShips) do
        ShipListManager.createShipUIElement(v.index, ships, shipListEx, shipUuidToRow)
    end
end
function ShipListManager.createShipUIElement(shipId, ships, shipListEx, shipUuidToRow)
    local entity = Entity(shipId)
    local miningMaterial, salvageMaterial = ShipValidation.getShipMiningAndSalvagingMaterial(shipId)
    local uuidStr
    pcall(function()
        if entity and entity.id then
            if type(entity.id) == "string" then
                uuidStr = entity.id
            elseif entity.id.string then
                uuidStr = entity.id.string
            else
                uuidStr = tostring(entity.id)
            end
        end
    end)
    uuidStr = tostring(uuidStr or ("id:" .. tostring(shipId)))
    shipListEx:addRow(entity.name)
    local rowIndex = shipListEx.rows - 1
    ships[tostring(shipId)].rowIndex = rowIndex
    shipUuidToRow[uuidStr] = rowIndex
    local color
    if miningMaterial then
        color = miningMaterial.color
    elseif salvageMaterial then
        color = salvageMaterial.color
    else
        color = ColorRGB(0.4,0.4,1)
    end
    local nameText = entity.name
    shipListEx:setEntry(1, rowIndex, nameText, false, false, color)
    shipListEx:setEntryType(1, rowIndex, ListBoxEntryType.Text)
    shipListEx:setEntryValue(1, rowIndex, uuidStr)
    shipListEx:setEntry(0, rowIndex, tostring(shipId), false, false, ColorRGB(0,0,0))
    shipListEx:setEntryType(0, rowIndex, ListBoxEntryType.Text)
    ShipListManager.setShipIconStatuses(shipId, ships, shipListEx)
end
function ShipListManager.setShipIconStatuses(shipIndex, ships, shipListEx)
    ShipStatusManager.setShipIconStatuses(shipIndex, ships, shipListEx)
end
function ShipListManager.tryRemoveShipFromList(shipId, ships, shipListEx)
    if ships[tostring(shipId)] ~= nil then
        local indexToRemove = ships[tostring(shipId)].rowIndex
        shipListEx:removeRow(indexToRemove)
        ships[tostring(shipId)] = nil
        if indexToRemove < getTableLength(ships) then
            for _, v in pairs(ships) do
                if v.rowIndex > indexToRemove then
                    v.rowIndex = v.rowIndex - 1
                end
            end
        end
    end
end
function ShipListManager.onShipNameUpdated(name, newName, ships, shipListEx)
    local shipId
    for i, v in pairs(ships) do
        if v.name == name then
            shipId = v.index
            v.name = newName
            local _, _, _, color, _ = shipListEx:getEntry(1, v.rowIndex)
            shipListEx:setEntry(1, v.rowIndex, newName, false, false, color)
            shipListEx:setEntryType(1, v.rowIndex, ListBoxEntryType.Text)
            shipListEx:setEntryValue(1, v.rowIndex, shipId)
            break
        end
    end
    return shipId
end
function ShipListManager.clearShipList(shipListEx, ships)
    shipListEx:clear()
    for k in pairs(ships) do
        ships[k] = nil
    end
    return ships
end
function ShipListManager.updateShipListFreeCargo(ships, recallFullShipsButton, setCargoFillPercentageCallback)
    for i, v in pairs(ships) do
        local ship = Entity(i)
        if ship and ship.freeCargoSpace and ship.maxCargoSpace and ship.maxCargoSpace > 0 then
            local freePercentage = ship.freeCargoSpace / ship.maxCargoSpace
            if freePercentage < 0 then freePercentage = 0 end
            local rowIndex = ships[tostring(i)].rowIndex
            setCargoFillPercentageCallback(rowIndex, freePercentage)
            if ship.freeCargoSpace < 150 then
                recallFullShipsButton.active = true
            end
        end
    end
end
function ShipListManager.recallFullShips(ships, recallFullShipsButton)
    recallFullShipsButton.active = false
    local shipIds = {}
    for i, _ in pairs(ships) do
        local ship = Entity(i)
        if ship.freeCargoSpace < 150 then
            table.insert(shipIds, i)
        end
    end
    local x, y = Sector():getCoordinates()
    invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "returnShipSquads", Player().craft.factionIndex, shipIds)
end
function ShipListManager.clearClickedShipId(shipSelectionChanged, clickedShipId)
    shipSelectionChanged = false
    clickedShipId = nil
    return shipSelectionChanged, clickedShipId
end
function ShipListManager.onShipSelected(index, ships, clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged)
    for _, v in pairs(ships) do
        local ship = Entity(v.index)
        if ship == nil then
            goto continue
        end
        local pilots = {ship:getPilotIndices()}
        if v.rowIndex == index and (not ship.hasPilot or (ship.hasPilot and pilots[Player().index])) then
            local actualShipUuid = ship.id
            local actualShipUuidStr
            if type(ship.id) == "string" then
                actualShipUuidStr = ship.id
            elseif ship.id.string then
                actualShipUuidStr = ship.id.string
            else
                actualShipUuidStr = tostring(ship.id)
            end
            clickedShipUuid = actualShipUuid
            clickedShipUuidStr = actualShipUuidStr
            if clickedShipId == nil then
                clickedShipId = ship.id -- keep for backward compatibility
                Player().selectedObject = ship
            elseif tostring(clickedShipId) == tostring(ship.id) then
                shipSelectionChanged = true
                Player().craft = ship
            else
                shipSelectionChanged = true
                clickedShipId = ship.id
                Player().selectedObject = ship
            end
            if shipSelectionChanged == false then
                break
            end
        end
        ::continue::
    end
    return clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged
end
function ShipListManager.onShipRowSelected(index, ships, clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged)
    return ShipListManager.onShipSelected(index, ships, clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged)
end
return ShipListManager
