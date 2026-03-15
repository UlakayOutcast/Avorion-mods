function FighterFactory.makeFighter(type, plan, turret, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)
    local material = Material()
    local rarity = Rarity()

    local tech = 35
    if turret then
        material = turret.material
        rarity = turret.rarity
        tech = turret.averageTech
    else
        material = getMostUsedMaterial(plan)
        rarity = CrewShuttleRarity()
    end

    local diameter, durability, turningSpeed, maxVelocity = FighterFactory.getStats(tech, rarity, material, sizePoints, durabilityPoints, turningSpeedPoints, velocityPoints)

    local fighter = FighterTemplate()

    local scale = diameter + lerp(diameter, fighter.minFighterDiameter, fighter.maxFighterDiameter, 0, 1.5)
    scale = scale / (plan.radius * 2)
    plan:scale(vec3(scale, scale, scale))
    fighter.plan = plan

    fighter.diameter = diameter
    fighter.durability = durability
    fighter.turningSpeed = turningSpeed
    fighter.maxVelocity = maxVelocity
	if material.value >= 2 then
		fighter.shield = durability * math.min((0.05 * material.value) + (0.1 * rarity.value), 1.0)
	end
    fighter.type = type

    if turret then
        local fireRateFactor = 1.0
        if turret.coolingType == 0 and turret.heatPerShot > 0 and tostring(turret.shootingTime) ~= "inf" then
            if turret.shotsUntilOverheated > 0 then
                fireRateFactor = turret.shootingTime / (turret.shootingTime + turret.coolingTime)
            end
        end

        for _, weapon in pairs({turret:getWeapons()}) do

            if weapon.damage ~= 0 then weapon.damage = weapon.damage * 0.4 / turret.slots end
            if weapon.shieldRepair ~= 0 then weapon.shieldRepair = weapon.shieldRepair * 0.4 / turret.slots end
            if weapon.hullRepair ~= 0 then weapon.hullRepair = weapon.hullRepair * 0.4 / turret.slots end
            if weapon.holdingForce ~= 0 then weapon.holdingForce = weapon.holdingForce * 0.4 / turret.slots end

            weapon.fireRate = weapon.fireRate * fireRateFactor
            weapon.reach = math.min(weapon.reach, 350)

            fighter:addWeapon(weapon)
        end

        for desc, value in pairs(turret:getDescriptions()) do
            fighter:addDescription(desc, value)
        end
    end

    return fighter
end