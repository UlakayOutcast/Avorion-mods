local ShipStatusManager = {}
function ShipStatusManager.setCargoFillPercentage(shipListEx, rowIndex, freePercentage)
    if freePercentage ~= freePercentage then
        shipListEx:setEntry(0, rowIndex, "data/textures/icons/cargo-hold.png", false, false, ColorRGB(1,0,0))
        shipListEx:setEntryType(0, rowIndex, ListBoxEntryType.Icon)
        shipListEx:setEntryTooltip(0, rowIndex, "Ship has no cargo bay"%_t)
    else
        shipListEx:setEntry(0, rowIndex, round((1-freePercentage) * 100, 0) .. "%", false, false, redToGreenGradient(freePercentage))
        shipListEx:setEntryType(0, rowIndex, ListBoxEntryType.Text)
        shipListEx:setEntryTooltip(0, rowIndex, "Cargo fill percentage"%_t)
    end
end
function ShipStatusManager.setShipIconStatuses(shipIndex, ships, shipListEx)
    if ships[tostring(shipIndex)] == nil then return end
    local pilots = 0
    local entity = Entity(shipIndex)
    if not entity then return end
    for profession, workforce in pairs(entity.crew:getWorkforce()) do
        if profession.value == CrewProfessionType.Pilot then
            if workforce >= 1200 then
                pilots = 120
                break
            end
        end
    end
    if pilots == 0 then
        pilots = ReadOnlyEntity(shipIndex).crew.pilots
    end
    local hangar = Hangar(shipIndex)
    local rowIndex = ships[tostring(shipIndex)].rowIndex
    local squads = {hangar:getSquads()}
    local fightersMissing = 0
    local supportedSquads = hangar.numSupportedSquads
    for _, v in pairs(squads) do
        fightersMissing = fightersMissing + hangar:getSquadFreeSlots(v)
    end
    local miningMaterial, salvageMaterial = ShipValidation.getShipMiningAndSalvagingMaterial(shipIndex)
    local mineTooltip = ""
    if miningMaterial then
        mineTooltip = "Able to mine "%_t .. Material(miningMaterial.value + 1).name
        if salvageMaterial then
            mineTooltip = mineTooltip .. "\n"
        end
    end
    if salvageMaterial then
        mineTooltip = mineTooltip .. "Able to salvage "%_t .. Material(salvageMaterial.value + 1).name
    end
    if miningMaterial == nil and salvageMaterial == nil then
        mineTooltip = "Ship has no fighters to mine"%_t
    end
    shipListEx:setEntryTooltip(1, rowIndex, mineTooltip)
    local cargoBay = CargoBay(shipIndex)
    local freePercentage = cargoBay.freeSpace / cargoBay.cargoHold
    ShipStatusManager.setCargoFillPercentage(shipListEx, rowIndex, freePercentage)
    if supportedSquads < #squads then
        shipListEx:setEntry(2, rowIndex, "data/textures/icons/hangar.png", false, false, ColorRGB(1, 1, 0))
        shipListEx:setEntryTooltip(2, rowIndex, "Ship needs more Fighter Control Systems"%_t)
    else
        shipListEx:setEntry(2, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(0, 0, 0))
    end
    if not Entity(shipIndex):getCaptain() then
        shipListEx:setEntry(3, rowIndex, "data/textures/icons/captain.png", false, false, ColorRGB(1, 0, 0))
        shipListEx:setEntryTooltip(3, rowIndex, "Ship has no captain"%_t)
    else
        shipListEx:setEntry(3, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(0, 0, 0))
    end
    if pilots == 0 then
        shipListEx:setEntry(4, rowIndex, "data/textures/icons/helmet.png", false, false, ColorRGB(1, 0, 0))
        shipListEx:setEntryTooltip(4, rowIndex, "Ship has no pilots"%_t)
    elseif pilots < hangar.numFighters then
        local pilotPercentage = pilots / hangar.numFighters
        shipListEx:setEntry(4, rowIndex, "data/textures/icons/helmet.png", false, false, redToGreenGradient(pilotPercentage))
        shipListEx:setEntryTooltip(4, rowIndex, "Pilots "%_t .. pilots .. "/" .. hangar.numFighters)
    else
        shipListEx:setEntry(4, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(0, 0, 0))
    end
    if #squads * 12 - fightersMissing == 0 then
        shipListEx:setEntry(5, rowIndex, "data/textures/icons/fighter.png", false, false, ColorRGB(1, 0, 0))
        shipListEx:setEntryTooltip(5, rowIndex, "Ship has no fighters"%_t)
    elseif fightersMissing > 0 then
        local fighterPercentage = (#squads * 12 - fightersMissing) / (#squads * 12)
        shipListEx:setEntry(5, rowIndex, "data/textures/icons/fighter.png", false, false, redToGreenGradient(fighterPercentage))
        shipListEx:setEntryTooltip(5, rowIndex, "Fighters "%_t .. #squads * 12 - fightersMissing .. "/" .. #squads * 12)
    else
        shipListEx:setEntry(5, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(0, 0, 0))
    end
    local cu = ControlUnit(shipIndex)
    if cu.hasPilot then
        local seat = cu:getSeats()[1]
        if seat then
            local playerIndex = seat.playerIndex
            shipListEx:setEntry(6, rowIndex, "data/textures/icons/player.png", false, false, ColorRGB(1, 1, 1))
            shipListEx:setEntryTooltip(6, rowIndex, Galaxy():getPlayerNames()[playerIndex])
        else
            shipListEx:setEntry(6, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(0, 0, 0))
        end
    else
        shipListEx:setEntry(6, rowIndex, "data/textures/icons/nothing.png", false, false, ColorRGB(0, 0, 0))
    end
    shipListEx:setEntryType(2, rowIndex, ListBoxEntryType.Icon)
    shipListEx:setEntryType(3, rowIndex, ListBoxEntryType.Icon)
    shipListEx:setEntryType(4, rowIndex, ListBoxEntryType.Icon)
    shipListEx:setEntryType(5, rowIndex, ListBoxEntryType.Icon)
    shipListEx:setEntryType(6, rowIndex, ListBoxEntryType.Icon)
end
return ShipStatusManager
