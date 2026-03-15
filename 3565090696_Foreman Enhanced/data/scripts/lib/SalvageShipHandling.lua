local SalvageShipHandling = {}
function SalvageShipHandling.startSalvagingWithShip(factionIndex, shipIndex, factionData, assignSalvageSquadsRandomly)
    local shipData = factionData[factionIndex].ships[tostring(shipIndex)]
    assignSalvageSquadsRandomly(factionIndex, shipIndex, shipData.miningSquads)
end
function SalvageShipHandling.startSalvagingPeriodic(factionIndex, factionData, getWreckages, getTableLength, addSquadsToWreckage)
    local fData = factionData[factionIndex]
    if fData then
        WreckageManagement.assignFactionSalvagingSquadsRandomly(factionIndex, fData.miningFilters, factionData, getWreckages, getTableLength, addSquadsToWreckage)
    end
end
return SalvageShipHandling
