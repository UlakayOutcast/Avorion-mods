local VelocityReductionFactor = 2

-- Функция для изменения параметров оружия
local function modifyWeapon(weapon, rand, dps, tech, material, rarity, arg6, arg7, arg8, arg9)
    if not weapon then
        return weapon
    end

    -- Проверяем, что это не лучевое оружие
    -- if weapon.continuousBeam ~= true then
	-- if weapon.continuousBeam ~= true and weapon.appearance ~= WeaponAppearance.MiningLaser and weapon.appearance ~= WeaponAppearance.Tesla and weapon.appearance ~= WeaponAppearance.Laser and weapon.appearance ~= WeaponAppearance.Repair and weapon.appearance ~= WeaponAppearance.RailGun and weapon.appearance ~= WeaponAppearance.RocketLauncher then
	if weapon.continuousBeam ~= true and (weapon.appearance == WeaponAppearance.ChainGun or weapon.appearance == WeaponAppearance.Bolter or weapon.appearance == WeaponAppearance.PulseCannon or weapon.appearance == WeaponAppearance.AntiFighter or weapon.appearance == WeaponAppearance.PlasmaGun or weapon.appearance == WeaponAppearance.Cannon) then
        -- Изменяем скорость снаряда
        if weapon.pvelocity and weapon.pvelocity > 0 then
            weapon.pvelocity = weapon.pvelocity / VelocityReductionFactor
        end

        -- Пересчитываем время жизни снаряда
        if weapon.pvelocity and weapon.pvelocity > 0 and weapon.reach and weapon.reach > 0 then
            weapon.pmaximumTime = weapon.reach / weapon.pvelocity
        end

        -- Изменяем задержку между выстрелами
        if weapon.fireDelay and weapon.fireDelay > 0 then
            weapon.fireDelay = weapon.fireDelay * VelocityReductionFactor
        end

        -- Пересчитываем урон
        if weapon.fireDelay and weapon.fireDelay > 0 then
            weapon.damage = dps * weapon.fireDelay
        end

        -- Изменяем размер снаряда
        if weapon.psize and weapon.psize > 0 then
            weapon.psize = weapon.psize * (weapon.damage / 50 + 1)
        end
	
    end

    return weapon
end

-- Переопределяем функции генерации оружия
if WeaponGenerator then
    for funcName, func in pairs(WeaponGenerator) do
        if type(func) == "function" and funcName:match("^generate") then
            local originalFunc = func
            -- Переопределяем функцию с сохранением оригинального названия
            WeaponGenerator[funcName] = function(rand, dps, tech, material, rarity, arg6, arg7, arg8, arg9)
                local weapon = originalFunc(rand, dps, tech, material, rarity, arg6, arg7, arg8, arg9)
                return modifyWeapon(weapon, rand, dps, tech, material, rarity, arg6, arg7, arg8, arg9)
            end
        end
    end
else
    print("WeaponGenerator не найден!")
end
