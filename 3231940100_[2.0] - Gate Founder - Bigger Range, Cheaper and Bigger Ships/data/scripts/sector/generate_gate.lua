package.path = package.path .. ";data/scripts/lib/?.lua"

include ("gate_util")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace PlayerGateGenerator
PlayerGateGenerator = {}

function PlayerGateGenerator.initialize(target_x, target_y, factionIndex)
    local x, y = Sector():getCoordinates()
    if onServer() then
        make_gate(target_x, target_y, factionIndex)
    end

    terminate()
end
