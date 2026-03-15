package.path = package.path .. ";data/scripts/lib/?.lua"
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Refinery

function Refinery.getRefiningTime(oreAmounts, scrapAmounts)
    local time = 0
    Refinery.productionCapacity = Plan():getStats().productionCapacity -- may need to synchronize this

    local capMinimumWork = 10000.0

    --                 Iron, Titanium, Naonite, Trinium, Xanion, Ogonite, Avorion
    local oreWork = {2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0} -- we base our 2k per second around trinium, below it faster, above longer
    local scrapWork = {0.8, 1.2, 1.6, 2.0, 2.4, 2.8, 3.2} -- scrap is 2.5x faster
    -- Rates are:      I = 5000/s T = 3333/s N = 2500/s Tr = 2000/s X = 1666/s O = 1444/s A = 1250/s
    -- Rates are:      I = 12500/s T = 8333/s N = 6250/s Tr = 5000/s X = 4166/s O = 3571/s A = 3125/s

    local workPerSecond = Refinery.productionCapacity
    -- make all refineries go at least at some capacity
    if workPerSecond < capMinimumWork then
        workPerSecond = capMinimumWork
    end

    for material, amount in pairs(oreAmounts) do
        time = time + (amount * oreWork[material])
    end

    for material, amount in pairs(scrapAmounts) do
        time = time + (amount * scrapWork[material])
    end

    if time == 0 then return 0 end

    return math.max(1, math.ceil(time / workPerSecond))
end
