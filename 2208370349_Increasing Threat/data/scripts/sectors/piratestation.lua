local _Debug = 0

local IncreasingThreat_generateShipyardSector = SectorTemplate.generate
function SectorTemplate.generate(player, seed, x, y)
    IncreasingThreat_generateShipyardSector(player, seed, x, y)

    if _Debug == 1 then
        print("Running IncreasingThreat_generateShipyardSector")
    end

    local _Shipyard = {Sector():getEntitiesByType(EntityType.Station)}
    for _, _Yard in pairs(_Shipyard) do
        _Yard:setValue("_increasingthreat_pirate_shipyard", true)
    end
end