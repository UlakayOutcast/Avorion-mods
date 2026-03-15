package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

ESCCUtil = include("esccutil")

--namespace LLTESide6Pirate
LLTESide6Pirate = {}
local self = LLTESide6Pirate

function LLTESide6Pirate.getUpdateInterval()
    return 1
end

function LLTESide6Pirate.updateServer(_TimeStep)
    local _Sector = Sector()
    local _Players = {_Sector:getPlayers()}
    if #_Players > 0 then
        local _PlayersWithScript = false
        for _, _Player in pairs(_Players) do
            if _Player:hasScript("lltesidemission6.lua") then
                _PlayersWithScript = true
                break
            end
        end

        local _Rgen = ESCCUtil.getRand()

        if not _PlayersWithScript then
            local _ShipAI = ShipAI()
            _ShipAI:setPassive()
            Entity():addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(2, 4))
        end
    end
end