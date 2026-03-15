--region #GENERAL PURPOSE

function ShipUtility.addScalableArtilleryEquipment(_Craft, _TurretFactor, _TorpedoFactor, _ResetNameAndIcon)
    local weaponTypes = ArtilleryWeapons
    local torpedoTypes = NormalTorpedoes

    _TurretFactor = _TurretFactor or 1.5
    _TorpedoFactor = _TorpedoFactor or 1.0
    _ResetNameAndIcon = _ResetNameAndIcon or false

    --Parameters for this - Craft / Weapon Types / Torpedo Types / Turret Factor / Torpedo Factor / Turret Range
    --Most of these are pass-through, but we're not going to throw turret range in.
    ShipUtility.addSpecializedEquipment(_Craft, weaponTypes, torpedoTypes, _TurretFactor, _TorpedoFactor)

    _Craft:setValue("is_armed", true)
    if _ResetNameAndIcon then
        _Craft:setTitle("${toughness}Artillery ${class}"%_T, {toughness = "", class = ShipUtility.getMilitaryNameByVolume(_Craft.volume)})
        _Craft:addScript("icon.lua", "data/textures/icons/pixel/artillery.png")
    end
end

function ShipUtility.addSpecificScalableWeapon(_Craft, _WeaponTypes, _TurretFactor, _TorpedoFactor, _TurretRange)
    local weaponTypes = _WeaponTypes or AttackWeapons
    local torpedoTypes = NormalTorpedoes

    _TurretFactor = _TurretFactor or 1.5
    _TorpedoFactor = _TorpedoFactor or 1.0

    --Parameters for this - Craft / Weapon Types / Torpedo Types / Turret Factor / Torpedo Factor / Turret Range
    --Most of these are pass through.
    --There are a lot of different possibilities here - no need to reset the type / icon.
    ShipUtility.addSpecializedEquipment(_Craft, weaponTypes, torpedoTypes, _TurretFactor, _TorpedoFactor, _TurretRange)
end

--endregion

--region #HORIZON BOSSES

function ShipUtility.addHorizonPrototypePlasmaGuns(_Craft, _TurretFactor)
    --Adds a battery of plasma mortars that are somewhat dangerous to shields, but not very dangerous to hull.
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)
    local _BaseTurretGen = include("turretgenerator")

    local _Rgen = random()

    local _PlasmaTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.PlasmaGun, nil)
    _PlasmaTurret.coaxial = false
    local _NumWeapons = _PlasmaTurret.numWeapons
    local _PlasmaWeapons = {_PlasmaTurret:getWeapons()}
    _PlasmaTurret:clearWeapons()

    local _BaseFireRate = _Rgen:getFloat(0.4, 0.6)
    local _CoolingTime = _Rgen:getInt(8, 10)
    local _ShootingTime = _Rgen:getInt(30, 35)
    local _ShotRange = _Rgen:getFloat(1100, 1500)

    for _, _W in pairs(_PlasmaWeapons) do
        _W.reach = _ShotRange
        _W.fireRate = _BaseFireRate / _NumWeapons
        _W.blength = _W.reach
        _W.psize = 8
        _W.shieldDamageMultiplier = _W.shieldDamageMultiplier * 1.25

        _PlasmaTurret:addWeapon(_W)
    end

    _BaseTurretGen.createBatteryChargeCooling(_PlasmaTurret, _CoolingTime, _ShootingTime)

    ShipUtility.addTurretsToCraft(_Craft, _PlasmaTurret, _TurretCount)
end

--endregion

--region #GORDIAN KNOT

function ShipUtility.addMegaSeekers(_Craft, _TurretFactor)
    _TurretFactor = _TurretFactor or 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _MissileTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.RocketLauncher, nil)
    _MissileTurret.coaxial = false
    local _MissileWeapons = {_MissileTurret:getWeapons()}
    _MissileTurret:clearWeapons()
    for _, _W in pairs(_MissileWeapons) do
        _W.damage = math.max(_W.damage * 2, 10000)
        _W.seeker = true
        _W.pvelocity = _W.pvelocity * 3
        _W.reach = _W.reach * 20
        _W.fireDelay = math.min(_W.fireRate, 1.5)
        _W.pmaximumTime = _W.reach / _W.pvelocity
        _W.explosionRadius = math.sqrt(_W.damage * 4)

        _MissileTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _MissileTurret, _TurretCount)
end

function ShipUtility.addMegaLasers(_Craft, _TurretFactor)
    _TurretFactor = _TurretFactor or 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)
    local rand = Random()

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _LaserTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.Laser, nil)
    _LaserTurret.coaxial = false
    local _LaserWeapons = {_LaserTurret:getWeapons()}
    _LaserTurret:clearWeapons()
    for _, _W in pairs(_LaserWeapons) do
        local hue = 0

        _W.bouterColor = ColorHSV(hue, 1, rand:getFloat(0.1, 0.3))
        _W.binnerColor = ColorHSV(hue + rand:getFloat(-120, 120), 0.3, rand:getFloat(0.7, 0.8))

        _W.bauraWidth = math.max(_W.bauraWidth * 4, 12)
        _W.bwidth = math.max(_W.bwidth * 4, 8)
        _W.damage = math.max(_W.damage * 4, 4000)
        _W.reach = _W.reach * 20
        _W.blength = _W.reach

        _LaserTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _LaserTurret, _TurretCount)    
end

function ShipUtility.addVelocityCannons(_Craft, _TurretFactor)
    _TurretFactor = _TurretFactor or 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _CannonTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.Cannon, nil)
    _CannonTurret.coaxial = false
    local _CannonWeapons = {_CannonTurret:getWeapons()}
    _CannonTurret:clearWeapons()
    for _, _W in pairs(_CannonWeapons) do
        _W.damage = math.max(_W.damage * 10, 20000)
        _W.pvelocity = _W.pvelocity * 1.75
        _W.reach = _W.reach * 20
        _W.fireDelay = math.min(_W.fireRate, 2)
        _W.pmaximumTime = _W.reach / _W.pvelocity
        _W.explosionRadius = math.sqrt(_W.damage * 3)
        --These used to have a force turret effect, but it was interfering with the ability of the laser and torpedoes to hit the target.
        --So I took it out.

        _CannonTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _CannonTurret, _TurretCount)
end

--endregion

--region #EXECUTIONER

local ExecutionerWeapons = {
    WeaponType.Bolter,
    WeaponType.PlasmaGun,
    WeaponType.PulseCannon,
    WeaponType.LightningGun,
    WeaponType.RailGun
}
ShipUtility.ExecutionerWeapons = ExecutionerWeapons

function ShipUtility.addExecutionerStandardEquipment(_Craft, _TurretFactor, _TorpedoFactor)
    local _WeaponTypes = ExecutionerWeapons
    local _TorpedoTypes = NormalTorpedoes

    ShipUtility.addSpecializedEquipment(_Craft, _WeaponTypes, _TorpedoTypes, _TurretFactor, _TorpedoFactor, 1500)
    _Craft:setTitle(ShipUtility.getMilitaryNameByVolume(_Craft.volume), {})
    _Craft:setValue("is_armed", true)

    _Craft:addScript("icon.lua", "data/textures/icons/pixel/military-ship.png")
end

--endregion

--region #ESCC BOSSES

function ShipUtility.addHellcatLasers(_Craft)
    local _TurretFactor = 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)
    local rand = Random()

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _LaserTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.Laser, nil)
    _LaserTurret.coaxial = false
    local _NumWeapons = _LaserTurret.numWeapons
    local _LaserWeapons = {_LaserTurret:getWeapons()}
    _LaserTurret:clearWeapons()

    --8/3/2021 - lol I found the laser bug and I didn't even realize.
    --Yeah I have no fucking clue what's going on here. Laser damage seems to be VERY dependent on # of slots for some reason????
    --So we multiply the base damage amount by the # of slots in the turret and then divide that by the # of weapons. This should keep the
    --RNG fairly consistent and not cause WILD variances (like 700k to 7 million)
    local _Damage = 2800 + rand:getInt(100, 450) * math.max(1, _LaserTurret.slots / 1.75)

    for _, _W in pairs(_LaserWeapons) do
        local hue = 182

        _W.bouterColor = ColorHSV(hue, 1, rand:getFloat(0.1, 0.3))
        _W.binnerColor = ColorHSV(hue + rand:getFloat(-120, 120), 0.3, rand:getFloat(0.7, 0.8))

        _W.bauraWidth = 16
        _W.bwidth = 11
        _W.damage = math.max(_W.damage, _Damage / _NumWeapons)
        _W.reach = 575
        _W.blength = _W.reach
        _W.shieldDamageMultiplier = 1.0
        _W.damageType = DamageType.Energy

        _LaserTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _LaserTurret, _TurretCount)    
end

function ShipUtility.addKatanaRailguns(_Craft)
    --Add a battery of burst fire railguns that are extremely dangerous to hulls, but not very dangerous to shields.
    local _TurretFactor = 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)
    local _BaseTurretGen = include("turretgenerator")

    local _Rgen = random()

    local _RailgunTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.RailGun, nil)
    _RailgunTurret.coaxial = false
    local _NumWeapons = _RailgunTurret.numWeapons
    local _RailgunWeapons = {_RailgunTurret:getWeapons()}
    _RailgunTurret:clearWeapons()

    local _BaseFireRate = 10
    local _CoolingTime = 10
    local _ShootingTime = 1
    local _Damage = 4599 + _Rgen:getInt(1, 100)

    for _, _W in pairs(_RailgunWeapons) do
        _W.damage = math.max(_W.damage, _Damage)
        _W.reach = 1850
        _W.fireRate = _BaseFireRate / _NumWeapons
        _W.bouterColor = ColorHSV(0, 0.6, 1.0)
        _W.binnerColor = ColorHSV(0, 1.0, 1.0)
        _W.blockPenetration = 12
        _W.bwidth = 1.5 --0.75
        _W.bauraWidth = 6 --4.5
        _W.hullDamageMultiplier = 2.3
        _W.shieldDamageMultiplier = 0.75
        _W.shieldPenetration = 0.0
        _W.damageType = DamageType.AntiMatter

        _RailgunTurret:addWeapon(_W)
    end

    _BaseTurretGen.createStandardCooling(_RailgunTurret, _CoolingTime, _ShootingTime)

    ShipUtility.addTurretsToCraft(_Craft, _RailgunTurret, _TurretCount)
end

function ShipUtility.addKatanaMortars(_Craft)
    --Adds a battery of plasma mortars that are extremely dangerous to shields, but not very dangerous to hull.
    local _TurretFactor = 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)
    local _BaseTurretGen = include("turretgenerator")

    local _Rgen = random()

    local _PlasmaTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.PlasmaGun, nil)
    _PlasmaTurret.coaxial = false
    local _NumWeapons = _PlasmaTurret.numWeapons
    local _PlasmaWeapons = {_PlasmaTurret:getWeapons()}
    _PlasmaTurret:clearWeapons()

    --Unlike the railguns, give the plasma guns a bit of wiggle room.
    local _BaseFireRate = _Rgen:getFloat(0.4, 0.6)
    local _CoolingTime = _Rgen:getInt(8, 10)
    local _ShootingTime = _Rgen:getInt(30, 35)
    local _Damage = 4099 + _Rgen:getInt(1, 100)

    for _, _W in pairs(_PlasmaWeapons) do
        _W.damage = math.max(_W.damage, _Damage)
        _W.reach = 1850
        _W.fireRate = _BaseFireRate / _NumWeapons
        _W.blength = _W.reach
        _W.psize = 8
        _W.shieldDamageMultiplier = 4.8

        _PlasmaTurret:addWeapon(_W)
    end

    _BaseTurretGen.createBatteryChargeCooling(_PlasmaTurret, _CoolingTime, _ShootingTime)

    ShipUtility.addTurretsToCraft(_Craft, _PlasmaTurret, _TurretCount)
end

function ShipUtility.addGoliathLaunchers(_Craft)
    local _TurretFactor = 15

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _RocketTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.RocketLauncher, nil)
    _RocketTurret.coaxial = false
    local _NumWeapons = _RocketTurret.numWeapons
    local _RocketWeapons = {_RocketTurret:getWeapons()}
    _RocketTurret:clearWeapons()

    local _BaseFireRate = 1.0

    for _, _W in pairs(_RocketWeapons) do
        _W.damage = math.max(_W.damage, 8000)
        _W.reach = 4500
        _W.fireDelay = _BaseFireRate / _NumWeapons
        _W.pvelocity = 6
        _W.pmaximumTime = _W.reach / _W.pvelocity
        _W.explosionRadius = math.sqrt(_W.damage * 3)
        _W.seeker = true

        _RocketTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _RocketTurret, _TurretCount)
end

function ShipUtility.addVigShieldCannons(_Craft)
    local _TurretFactor = 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _Rgen = random()

    local _CannonTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.Cannon, nil)
    _CannonTurret.coaxial = false
    local _CannonWeapons = {_CannonTurret:getWeapons()}
    _CannonTurret:clearWeapons()

    local _Damage = 12000 + _Rgen:getInt(500, 1000)

    for _, _W in pairs(_CannonWeapons) do
        _W.damage = math.max(_W.damage, _Damage)
        _W.reach = 3800
        _W.fireDelay = 1.2
        _W.pmaximumTime = _W.reach / _W.pvelocity
        _W.explosionRadius = math.sqrt(_W.damage * 3.5)

        _CannonTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _CannonTurret, _TurretCount)
end

function ShipUtility.addPhoenixCannons(_Craft)
    --Add a battery of burst fire cannons that are very dangerous to hulls, and only moderately dangerous to shields.
    local _TurretFactor = 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)
    local _BaseTurretGen = include("turretgenerator")

    local _Rgen = random()

    local _CannonTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.Cannon, nil)
    _CannonTurret.coaxial = false
    local _NumWeapons = _CannonTurret.numWeapons
    local _CannonWeapons = {_CannonTurret:getWeapons()}
    _CannonTurret:clearWeapons()

    local _BaseFireRate = 10
    local _CoolingTime = 21
    local _ShootingTime = 1.25
    local _Damage = 10000 + _Rgen:getInt(1, 500)

    for _, _W in pairs(_CannonWeapons) do
        _W.damage = math.max(_W.damage, _Damage)
        _W.reach = 2400
        _W.fireRate = _BaseFireRate / _NumWeapons
        _W.explosionRadius = math.sqrt(_W.damage * 3)

        _CannonTurret:addWeapon(_W)
    end

    _BaseTurretGen.createStandardCooling(_CannonTurret, _CoolingTime, _ShootingTime)

    ShipUtility.addTurretsToCraft(_Craft, _CannonTurret, _TurretCount)
end

function ShipUtility.addHunterRailguns(_Craft)
    --Add a battery of long-range, slow-firing railguns.
    local _TurretFactor = 10

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)
    local _BaseTurretGen = include("turretgenerator")

    local _Rgen = random()

    local _RailgunTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.RailGun, nil)
    _RailgunTurret.coaxial = false
    local _NumWeapons = _RailgunTurret.numWeapons
    local _RailgunWeapons = {_RailgunTurret:getWeapons()}
    _RailgunTurret:clearWeapons()

    local _Damage = 20500 + _Rgen:getInt(0, 500)
    local _BaseFireRate = 0.25

    for _, _W in pairs(_RailgunWeapons) do
        _W.damage = math.max(_W.damage, _Damage)
        _W.reach = 11000
        _W.fireRate = _BaseFireRate / _NumWeapons
        _W.bouterColor = ColorHSV(240, 0.6, 1.0)
        _W.binnerColor = ColorHSV(240, 1.0, 1.0)
        _W.blockPenetration = 20
        _W.bwidth = 1.5 --0.75
        _W.bauraWidth = 6 --4.5
        _W.hullDamageMultiplier = 1
        _W.damageType = DamageType.Physical

        _RailgunTurret:addWeapon(_W)
    end

    _BaseTurretGen.createStandardCooling(_RailgunTurret, 5, 20)

    ShipUtility.addTurretsToCraft(_Craft, _RailgunTurret, _TurretCount)
end

function ShipUtility.addHunterLightningGuns(_Craft)
    --Add a battery of long-range, slow-firing lightning guns.
    local _TurretFactor = 10
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * _TurretFactor + 2
    local _Generator = SectorTurretGenerator(_Seed)
    local _BaseTurretGen = include("turretgenerator")

    local _Rgen = random()

    local _LightningTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.LightningGun, nil)
    _LightningTurret.coaxial = false
    local _NumWeapons = _LightningTurret.numWeapons
    local _LightningWeapons = {_LightningTurret:getWeapons()}
    _LightningTurret:clearWeapons()

    local _Damage = 19500 + _Rgen:getInt(0, 500)
    local _BaseFireRate = 0.25

    for _, _W in pairs(_LightningWeapons) do
        _W.damage = math.max(_W.damage, _Damage)
        _W.reach = 11000
        _W.fireRate = _BaseFireRate / _NumWeapons
        _W.bouterColor = ColorHSV(240, 0.6, 1.0)
        _W.binnerColor = ColorHSV(240, 1.0, 1.0)
        _W.bwidth = 0.75
        _W.bauraWidth = 3
        _W.bshapeSize = 16

        _LightningTurret:addWeapon(_W)
    end

    _BaseTurretGen.createBatteryChargeCooling(_LightningTurret, 5, 20)

    ShipUtility.addTurretsToCraft(_Craft, _LightningTurret, _TurretCount)
end

--endregion

--region #XSOTAN

function ShipUtility.addPulverizerCannons(_Craft)
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * 0.75
    local _Generator = SectorTurretGenerator(_Seed)

    local _CannonTurret = _Generator:generate(_X, _Y, 0, nil, WeaponType.Cannon, nil)
    _CannonTurret.coaxial = false
    local _CannonWeapons = {_CannonTurret:getWeapons()}
    _CannonTurret:clearWeapons()

    for _, _W in pairs(_CannonWeapons) do
        _W.damage = _W.damage / 5
        _W.pvelocity = _W.pvelocity / 2
        _W.pmaximumTime = _W.reach / _W.pvelocity
        _W.otherForce = _W.damage * 85000

        _CannonTurret:addWeapon(_W)
    end

    ShipUtility.addTurretsToCraft(_Craft, _CannonTurret, _TurretCount)
end

function ShipUtility.addRevenantArtillery(_Craft)
    local weaponTypes = ArtilleryWeapons
    local torpedoTypes = NormalTorpedoes

    --Only half as many turrets as usual* + very long range + no torpedoes.
    local turretFactor = 0.5
    local damageFactor = 1.0
    --See if the wreckage that got reanimated is especially large relative to other ships in the sector.
    local x, y = Sector():getCoordinates()
    local sectorShipVolume = Balancing_GetSectorShipVolume(x, y)

    local volumeRatio = _Craft.volume / sectorShipVolume

    --print("sector ship volume is " .. tostring(sectorShipVolume) .. " volume is " .. tostring(_Craft.volume) .. " ratio is " .. tostring(volumeRatio))

    if volumeRatio > 100 then
        turretFactor = turretFactor * (volumeRatio / 5)
        if turretFactor > 20 then
            local excessFactor = turretFactor - 20
            turretFactor = 20
            damageFactor = 1 + (excessFactor / 10)
        end
    end

    turretFactor = math.max(0.5, turretFactor)
    damageFactor = math.max(1.0, damageFactor)

    --print("final turret factor is " .. tostring(turretFactor) .. " final damage factor is " .. tostring(damageFactor))

    ShipUtility.addSpecializedEquipment(_Craft, weaponTypes, torpedoTypes, turretFactor, 0, 6000)

    _Craft.damageMultiplier = (_Craft.damageMultiplier or 1) * damageFactor
    _Craft:setValue("is_armed", true)
end

--endregion