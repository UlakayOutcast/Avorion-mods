
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";?"

include ("galaxy")
include ("randomext")
local TradingUtility = include ("tradingutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Traders
Traders = {}

if onServer() then

function Traders.getUpdateInterval()
    return 60
end

function Traders.getSpawnableTraders(entity, script)
    -- generally, buyers and sellers are both always possible
    local buyerPossible = true
    local sellerPossible = true

    -- for factories, the base price determines the relation between buyers and sellers
    -- the seller probability is the likelyhood for a ship that SELLS goods TO THE STATION
    local ok, pSeller = entity:invokeFunction(script, "getSellerProbability")
    if ok == 0 and pSeller then
        sellerPossible = random():test(pSeller)
        buyerPossible = not sellerPossible
    end

    return buyerPossible, sellerPossible
end

function Traders.isSpawnCandidate(station)
    local docks = DockingPositions(station)
    if not docks then return end

    if docks.numDockingPositions == 0 or not docks.docksEnabled then return end
    if TradingUtility.hasTraders(station) then return end

    if station:getValue("minimum_population_fulfilled") == false then -- explicitly check for 'false'
        return
    end

    return true
end

function Traders.update(timeStep)

    local sector = Sector()
    if sector:getValue("war_zone") then return end
    if sector:getValue("no_trade_zone") then return end

    local x, y = sector:getCoordinates()
    if Galaxy():sectorInRift(x, y) then return end

    -- find all stations that buy or sell goods
    local scripts = TradingUtility.getTradeableScripts()

    local tradingStations = {}

    local stations = {sector:getEntitiesByType(EntityType.Station)}
    for _, station in pairs(stations) do

        if Traders.isSpawnCandidate(station) then

            for _, script in pairs(scripts) do

                local tradingStation = nil

                if TradingUtility.getSellsToOthers(station, script) then
                    local results = {station:invokeFunction(script, "getSoldGoods")}
                    local callResult = results[1]

                    if callResult == 0 then -- call was successful, the station sells goods
                        tradingStation = {station = station, script = script, bought = {}, sold = {}}
                        tradingStation.sold = {}

                        for i = 2, tablelength(results) do
                            table.insert(tradingStation.sold, results[i])
                        end
                    end
                end

                if TradingUtility.getBuysFromOthers(station, script) then
                    local results = {station:invokeFunction(script, "getBoughtGoods")}
                    local callResult = results[1]
                    if callResult == 0 then -- call was successful, the station buys goods

                        if tradingStation == nil then
                            tradingStation = {station = station, script = script, bought = {}, sold = {}}
                        end

                        for i = 2, tablelength(results) do
                            table.insert(tradingStation.bought, results[i])
                        end

                    end
                end

                if tradingStation then
                    table.insert(tradingStations, tradingStation)
                end
            end
        end
    end

    -- potential early exit here
    if #tradingStations == 0 then return end

    local x, y = sector:getCoordinates()

    -- find stations that need goods or would sell goods
    local tradingPossibilities = {}

    for _, v in pairs(tradingStations) do
        local station = v.station
        local bought = v.bought
        local sold = v.sold
        local script = v.script

        local buyerPossible, sellerPossible = Traders.getSpawnableTraders(station, script)
        if buyerPossible then
            -- these are all possibilities for goods to be bought from stations
            for _, name in pairs(sold) do
                local err, amount, maxAmount = station:invokeFunction(script, "getStock", name)
                if err == 0 and maxAmount > 0 and amount / maxAmount > 0.6 then
                    table.insert(tradingPossibilities, {tradeType = TradingUtility.TradeType.BuyFromStation, station = station, script = script, name = name})
                end
            end
        end

        if sellerPossible then
            -- these are all possibilities for goods to be sold to stations
            for _, name in pairs(bought) do
                local err, amount, maxAmount = station:invokeFunction(script, "getStock", name)
                if err == 0 and maxAmount > 0 and amount / maxAmount < 0.4 then

                    local amountTraded = maxAmount - amount

                    if TradingUtility.isScriptAConsumer(script) then
                        if station.playerOwned or station.allianceOwned then
                            local g = goods[name]
                            if not g then
                                print ("invalid good: '" .. name .. "'")
                                return
                            end

                            local credits = math.random(500000, 3000000)
                            local maxValue = Balancing_GetSectorRichnessFactor(x, y, credits)
                            amountTraded = math.min(amountTraded, math.max(2, math.ceil(maxValue / g.price)))
                        end
                    end

                    table.insert(tradingPossibilities, {tradeType = TradingUtility.TradeType.SellToStation, station = station, script = script, name = name, amount = amountTraded})
                end
            end
        end
    end

    -- if there is no way for trade, exit
    if #tradingPossibilities == 0 then return end

    -- choose one at random
    local trade = tradingPossibilities[getInt(1, #tradingPossibilities)]

    -- create a trader ship that will fly to this station to trade
    -- don't create traders when there are no players in the sector to witness it. instead, do the trade transaction immediately
    TradingUtility.spawnTrader(trade, Traders, sector.numPlayers == 0)
end



end
