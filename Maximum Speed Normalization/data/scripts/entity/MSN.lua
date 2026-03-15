package.path = package.path .. ";data/scripts/lib/?.lua"
--maximum speed normalization 
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MaximumSpeedNormalization
MaximumSpeedNormalization = {}

-- CapTable = {}
-- CapTable[ "LessThanThreeSlot" ] = 1
-- CapTable[ "LessThanSixSlot" ] = .9
-- CapTable[ "LessThanNineSlot" ] = .55
-- CapTable[ "LessThanTwelveSlot"] = .25
-- CapTable[ "LessThanFifteenSlot" ] = .10
-- CapTable[ "GreaterThanFifteenSlot" ] = .05

function MaximumSpeedNormalization.initialize()
    if onServer() then
        local entity = Entity()
        entity:registerCallback("onBlockPlanChanged" , "applySpeedCap")
        entity:registerCallback("onCrewChanged", "applySpeedCap")
        entity:registerCallback("onSystemsChanged", "applySpeedCap")

        MaximumSpeedNormalization.applySpeedCap()
    end
end

function MaximumSpeedNormalization.applySpeedCap()
    -- local shipSystem = ReadOnlyShipSystem()
    local shipEngine = Engine()

    -- set bias to 1 so it isn't accounted for in calculation
    Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", 1 )

    -- disable boost maybe?
    shipEngine.boost = true

    -- apply appropriate bias
    -- if( shipSystem.numSlots < 3 )
    -- then
        -- Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", CapTable[ "LessThanThreeSlot" ] )
    -- elseif( shipSystem.numSlots < 6 )
    -- then
        -- Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", CapTable[ "LessThanSixSlot" ] )
    -- elseif( shipSystem.numSlots < 9 )
    -- then
        -- Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", CapTable[ "LessThanNineSlot" ] )
    -- elseif( shipSystem.numSlots < 12 )
    -- then
        -- Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", CapTable[ "LessThanTwelveSlot" ] )
    -- elseif( shipSystem.numSlots < 15 )
    -- then
        -- Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", CapTable[ "LessThanFifteenSlot" ] )
    -- else

        -- Entity():addKeyedMultiplier( StatsBonuses.Velocity, "SpeedCap", CapTable[ "GreaterThanFifteenSlot" ] )
    -- end
	
	
	
	local ship = Entity()
	if ship then
		local mass = ship.mass or 1  -- масса в кг, если 0 — ставим 1, чтобы избежать деления на ноль
		-- Рассчитываем множитель скорости: чем больше масса, тем больше множитель (компенсация)
		-- local speedMultiplier = 46.00 / math.sqrt(mass) +0.3  -- вычесляем влияние массы на скорость
		-- local speedMultiplier = 299792458 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость
		-- local speedMultiplier = 51.55 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость (48.85=930m/s on 1x1x1 engine, что в 10 раз больше стандарта)
		local speedMultiplier = 160.8 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость (160.8=2997m/s on 1x1x1 engine)
		-- local speedMultiplier = 16236.2 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость (16236.2=299782m/s on 1x1x1 engine) 299792458m/s light speed
		ship:addKeyedMultiplier(StatsBonuses.Velocity, "SpeedCap", speedMultiplier) -- применяем множитель
		
		local accelerationMultiplier = 1 - math.sqrt(mass) / 100 + 0.3  -- вычесляем влияние массы на ускорение
		ship:addKeyedMultiplier(StatsBonuses.Acceleration , "AccelerationCap", accelerationMultiplier) -- применяем множитель
	end

	
end
