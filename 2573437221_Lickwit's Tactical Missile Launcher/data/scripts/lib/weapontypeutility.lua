-- added stripminer
function legacyDetectWeaponType(item)
    local legacyTypeByIcon = {}
    legacyTypeByIcon["data/textures/icons/minigun.png"] = WeaponType.ChainGun
--    legacyTypeByIcon["data/textures/icons/minigun.png"] = WeaponType.PointDefenseChainGun
    legacyTypeByIcon["data/textures/icons/laser-blast.png"] = WeaponType.Laser
--    legacyTypeByIcon["data/textures/icons/laser-blast.png"] = WeaponType.PointDefenseLaser
    legacyTypeByIcon["data/textures/icons/mining.png"] = WeaponType.MiningLaser
	legacyTypeByIcon["data/textures/icons/s-mining-laser.png"] = WeaponType.StripMiner
	legacyTypeByIcon["data/textures/icons/TML.png"] = WeaponType.TMLauncher
    legacyTypeByIcon["data/textures/icons/recycle.png"] = WeaponType.SalvagingLaser
    legacyTypeByIcon["data/textures/icons/tesla-turret.png"] = WeaponType.PlasmaGun
    legacyTypeByIcon["data/textures/icons/missile-swarm.png"] = WeaponType.RocketLauncher
    legacyTypeByIcon["data/textures/icons/hypersonic-bolt.png"] = WeaponType.Cannon
    legacyTypeByIcon["data/textures/icons/beam.png"] = WeaponType.RailGun
    legacyTypeByIcon["data/textures/icons/laser-heal.png"] = WeaponType.RepairBeam
    legacyTypeByIcon["data/textures/icons/sentry-gun.png"] = WeaponType.Bolter
    legacyTypeByIcon["data/textures/icons/lightning-branches.png"] = WeaponType.LightningGun
    legacyTypeByIcon["data/textures/icons/lightning-frequency.png"] = WeaponType.TeslaGun
    legacyTypeByIcon["data/textures/icons/echo-ripples.png"] = WeaponType.ForceGun
    legacyTypeByIcon["data/textures/icons/pulsecannon.png"] = WeaponType.PulseCannon
    legacyTypeByIcon["data/textures/icons/flak.png"] = WeaponType.AntiFighter

    local type = legacyTypeByIcon[item.weaponIcon]

    -- detect point defense weapons
    if item.damageType == DamageType.Fragments then
        if type == WeaponType.ChainGun then
            type = WeaponType.PointDefenseChainGun
        elseif type == WeaponType.Laser then
            type = WeaponType.PointDefenseLaser
        end
    end

    return type
end
