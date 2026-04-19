package.path = package.path .. ";data/scripts/lib/?.lua"
--maximum speed normalization 
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MaximumSpeedNormalization
MaximumSpeedNormalization = {}

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
    -- disable boost maybe?
    -- shipEngine.boost = true

	local ship = Entity()
	if ship then
		local mass = ship.mass or 1  -- масса в кг, если 0 — ставим 1, чтобы избежать деления на ноль
		-- Рассчитываем множитель скорости: чем больше масса, тем больше множитель (компенсация)
		-- local speedMultiplier = 46.00 / math.sqrt(mass) +0.3  -- вычесляем влияние массы на скорость
		-- local speedMultiplier = 299792458 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость
		-- local speedMultiplier = 51.55 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость (48.85=930m/s on 1x1x1 engine, что в 10 раз больше стандарта)
		-- local speedMultiplier = 16236.2 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость (16236.2=299782m/s on 1x1x1 engine) 299792458 m/s light speed
		-- local speedMultiplier = 160.8 / math.sqrt(mass) + 0.3  -- вычесляем влияние массы на скорость (160.8=2997m/s on 1x1x1 engine)
		-- local speedMultiplier = 117.65 / math.sqrt(mass) + 8.845
		local speedMultiplier = 11.74 / math.sqrt(mass) + 0.88
		ship:addKeyedMultiplier(StatsBonuses.Velocity, "SpeedCap", speedMultiplier) -- применяем множитель
		
		-- local speedMultiplier = 160.8 / math.sqrt(mass) + 0.3 
		-- ship:addAbsoluteBias(StatsBonuses.Velocity, 1)
		
		-- ускорение
		-- local accelerationMultiplier = 1 - math.sqrt(mass) / 100 + 0.666  -- вычесляем влияние массы на ускорение
		-- ship:addKeyedMultiplier(StatsBonuses.Acceleration, "AccelerationCap", accelerationMultiplier) -- применяем 
		
		-- вращение
		-- ship:addKeyedMultiplier(StatsBonuses.yawMultiplie , "YawCap", 0.5)
		-- ship:addKeyedMultiplier(StatsBonuses.pitcMultiplie , "PitcCap", 0.5)
		-- ship:addKeyedMultiplier(StatsBonuses.rollMultiplie , "RollnCap", 0.5)
	end
end
