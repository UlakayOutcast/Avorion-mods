function WeaponGenerator.generateEmergencyWeapon(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    -- Weapon Firing and Projectile Stats
    local fireDelay = rand:getFloat(0.05, 0.1) 
    local reach = rand:getFloat(475, 800)       
    local damage = dps * fireDelay * 1.25      
    local speed = rand:getFloat(400, 800)       
    local existingTime = reach / speed

    -- Weapon Details
    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.seeker = true
    weapon.appearance = WeaponAppearance.AntiFighter
    weapon.name = "Emergency Weapon System /* Weapon Name*/"%_t
    weapon.prefix = "Emergency Weapon /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/Emergency-Gun.png" 
    weapon.sound = "pulsecannon"
    weapon.accuracy = 0.95 - rand:getFloat(0.01, 0.05)

    -- Impact Details
    weapon.damage = damage
    weapon.damageType = DamageType.Plasma
    weapon.impactParticles = ImpactParticles.Energy
    weapon.impactSound = 1

    -- 20 % chance for anti matter damage. 
    if rand:test(0.2) then
        WeaponGenerator.addAntiMatterDamage(rand, weapon, rarity, 2, 0.15, 0.2)
    end

    -- Projectile Shape and Effects
    weapon.psize = rand:getFloat(0.1, 0.2)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)
    weapon.pshape = ProjectileShape.Plasma

    -- Weapon Adaption
    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    -- Final Weapon Stat Tweaks (Has to be assigned last incase of adjustments due to previous damage changes)
    weapon.recoil = weapon.damage * 7
    weapon.damage = (weapon.damage * 3.5) / weapon.shotsFired

    return weapon
end

generatorFunction[WeaponType.EmergencyWeapon] = WeaponGenerator.generateEmergencyWeapon