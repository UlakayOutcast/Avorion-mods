function MissionUT.getNearbyFactions(x, y, d)
    d = d or 125

    local homeSectors = Galaxy():getMapHomeSectors(x, y, d)
    
    local _result = {}
    for idx, coords in pairs(homeSectors) do
        table.insert(_result, Faction(idx))
    end

    return _result
end