local old_generateMiningLaser = WeaponGenerator.generateMiningLaser
local old_generateSalvagingLaser = WeaponGenerator.generateSalvagingLaser
local old_generateRawMiningLaser = WeaponGenerator.generateRawMiningLaser
local old_generateRawSalvagingLaser = WeaponGenerator.generateRawSalvagingLaser

-- (rarity.value+1) is because rarity starts at -1
-- (tech / 50) = tech / No. tech levels, /100 for half the value
-- Some values may go higher than commented here due to bonuses rolled on generation, e.g. Long-Range
function WeaponGenerator.generateMiningLaser(rand, dps, tech, material, rarity)
	local weapon = old_generateMiningLaser(rand, dps, tech, material, rarity)

    weapon.reach = math.floor(50 + ((tech / 50) * 250) + (((rarity.value + 1) / 7) * 100)) -- Scales with tech & rarity. 225 at t50, 350 more at Legendary for total 8km
    weapon.damage = (dps * ((tech / 100)+1) * ((((rarity.value+1)/6)*0.25)+1)) * weapon.fireDelay -- Scales with tech & rarity. 0.5 per tech, 0.25 per rarity
	weapon.stoneRefinedEfficiency = math.abs(0.15 + ((tech / 50) * 0.15) + (((rarity.value + 1) / 6) * 0.15)) -- Scales with tech & rarity. 15% at t50, 15% at Legendary, total 45%

    weapon.bouterColor = ColorRGB(material.color.r * 0.25, material.color.g * 0.25, material.color.b * 0.25) -- colours based on material, vanilla was grey

    weapon.bwidth = math.min(math.max(weapon.damage * 0.04, 0.4), 1.5) -- scales off 4% damage 0.4-1.5 size
    weapon.bauraWidth = 2 * weapon.bwidth

	return weapon
end

function WeaponGenerator.generateSalvagingLaser(rand, dps, tech, material, rarity)
	local weapon = old_generateSalvagingLaser(rand, dps, tech, material, rarity)

    weapon.reach = math.floor(50 + ((tech / 50) * 250) + (((rarity.value + 1) / 7) * 100)) -- Max 4km
    weapon.damage = (dps * ((tech / 100)+1) * ((((rarity.value+1)/6)*0.25)+1)) * weapon.fireDelay
    weapon.hullDamageMultiplier = 2
	weapon.metalRefinedEfficiency = math.abs(0.15 + ((tech / 50) * 0.15) + (((rarity.value + 1) / 6) * 0.15)) -- Max 45%

    weapon.bouterColor = ColorRGB(material.color.r * 0.25, material.color.g * 0.25, material.color.b * 0.25)

    weapon.bwidth = math.min(math.max(weapon.damage * 0.04, 0.4), 1.5)
    weapon.bauraWidth = 2 * weapon.bwidth

	return weapon
end

function WeaponGenerator.generateRawMiningLaser(rand, dps, tech, material, rarity)
	local weapon = old_generateRawMiningLaser(rand, dps, tech, material, rarity)

    weapon.reach = math.floor(100 + ((tech / 50) * 500) + (((rarity.value + 1) / 7) * 200)) -- Max 8km
    weapon.damage = (dps * ((tech / 50)+1) * ((((rarity.value+1)/6)*0.5)+1)) * weapon.fireDelay -- 1 per tech, 0.5 per rarity, double refining laser
	weapon.stoneRawEfficiency = math.abs(0.30 + ((tech / 50) * 0.30) + (((rarity.value + 1) / 6) * 0.30)) -- Max 90%

    weapon.bouterColor = ColorRGB(material.color.r * 0.25, material.color.g * 0.25, material.color.b * 0.25)

    weapon.bwidth = math.min(math.max(weapon.damage * 0.04, 0.4), 1.5)
    weapon.bauraWidth = 1.5 * weapon.bwidth

	return weapon
end

function WeaponGenerator.generateRawSalvagingLaser(rand, dps, tech, material, rarity)
	local weapon = old_generateRawSalvagingLaser(rand, dps, tech, material, rarity)

    weapon.reach = math.floor(100 + ((tech / 50) * 500) + (((rarity.value + 1) / 7) * 200)) -- Max 8km
    weapon.damage = (dps * ((tech / 50)+1) * ((((rarity.value+1)/6)*0.5)+1)) * weapon.fireDelay -- 1 per tech, 0.5 per rarity, double refining laser
    weapon.hullDamageMultiplier = 2
	weapon.metalRawEfficiency = math.abs(0.30 + ((tech / 50) * 0.30) + (((rarity.value + 1) / 6) * 0.30)) -- Max 90%

    weapon.bouterColor = ColorRGB(material.color.r * 0.25, material.color.g * 0.25, material.color.b * 0.25)

    weapon.bwidth = math.min(math.max(weapon.damage * 0.04, 0.4), 1.5)
    weapon.bauraWidth = 1.5 * weapon.bwidth

	return weapon
end