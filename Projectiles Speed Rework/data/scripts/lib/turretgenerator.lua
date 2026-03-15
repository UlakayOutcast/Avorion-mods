local oldTurretGenerator_scale = TurretGenerator.scale
function TurretGenerator.scale(rand, turret, type, tech, turnSpeedFactor, coaxialPossible)
    if type ~= "PointDefenseLaser" or "Laser" or "LightningGun" or "TeslaGun" or "ForceGun" or "RailGun" or "Cannon" or "RocketLauncher" then 
        local newFactor = turnSpeedFactor * 2 
        local lvl = oldTurretGenerator_scale(rand, turret, type, tech, newFactor, coaxialPossible)
        return lvl
    elseif type == "LightningGun" or "TeslaGun" or "Laser" then
        local newFactor = turnSpeedFactor * 0.2
        local lvl = oldTurretGenerator_scale(rand, turret, type, tech, newFactor, coaxialPossible)
        return lvl
    elseif type == "RailGun" or "PlasmaGun" then
        local newFactor = turnSpeedFactor * 0.5
        local lvl = oldTurretGenerator_scale(rand, turret, type, tech, newFactor, coaxialPossible)
        return lvl
    else
        local lvl = oldTurretGenerator_scale(rand, turret, type, tech, turnSpeedFactor, coaxialPossible) 
        return lvl
    end
end