local oldInitialize = StationFounder.initialize or function() end
function StationFounder.initialize(shipyardFaction)
    oldInitialize(shipyardFaction)

    --Add our new bank station to the list.
    table.insert(StationFounder.stations, 
        {
            name = "Space Gate Builder"%_t,
            tooltip = "Local space gate. It will need to be paired with one in another sector"%_t,
            scripts = {
                {script = "data/scripts/entity/player_gate_builder.lua"}
            },
            getPrice = function()
                return 1 * 1000000
            end
        }
    )
end
