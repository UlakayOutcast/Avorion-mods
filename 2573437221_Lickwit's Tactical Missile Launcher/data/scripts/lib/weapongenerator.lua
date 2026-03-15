
function WeaponGenerator.generateTMLauncher(rand, dps, tech, material, rarity, numWeapons, coolingTime, shotCount)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = 1.0 * numWeapons
    local reach = rand:getFloat(2000, 2300)
    local speed = rand:getFloat(220, 250)
    local existingTime = reach / speed
    local turningSpeed = 0.11
    local damage = dps * 0.55 * (coolingTime / (numWeapons * shotCount)) --The damage calculation is a bit messy but this seems to be decently balanced. 
    local ProjectileSize = 1.25

    weapon.fireDelay = fireDelay
    weapon.damage = damage
    weapon.icon = "data/textures/icons/TML.png"
    weapon.name = "Tactical-Missile-Launcher /* Weapon Name*/"%_t
    weapon.prefix = "TM Launcher /* Weapon Prefix*/"%_t
    weapon.sound = "TML"
    weapon.accuracy = 0.999 - rand:getFloat(0, 0.01)
    weapon.appearance = WeaponAppearance.RocketLauncher
    weapon.impactParticles = ImpactParticles.Explosion
    weapon.impactExplosion = true
    weapon.reach = reach
    
    weapon.pshape = ProjectileShape.Rocket
    weapon.psize = ProjectileSize
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.seeker = true
    weapon.pangularVelocity = turningSpeed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)
    weapon.blockPenetration = rand:getInt(2, 3 + rarity.value * 2)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.impactSound = 1

    if GameVersion() >= Version(0, 31, 0) then
        -- 10 % chance for antimatter
        if rand:test(0.1) then
            WeaponGenerator.addAntiMatterDamage(rand, weapon, 2, 0.15, rarity, 0.2)
        end
    end
    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 10
    weapon.explosionRadius = math.sqrt(weapon.damage * 10.0) 

    return weapon
end

generatorFunction[WeaponType.TMLauncher] = WeaponGenerator.generateTMLauncher
