local CaptainUtility = include ("captainutility")

-- Hijack current On Captain Change function and append our own class benefits
local ExtCapts_CaptainShipBonuses_onCaptainChanged = CaptainShipBonuses.onCaptainChanged
function CaptainShipBonuses.onCaptainChanged(entityId, captain)
    if ExtCapts_CaptainShipBonuses_onCaptainChanged then
        ExtCapts_CaptainShipBonuses_onCaptainChanged(entityId, captain)
    end
	


    --[[
	--- Set any of these to true for there respective bonus
	highlightAsteroids = nil
    highlightWreckages = nil
    scientistInCommand = nil

    detectedAsteroids = nil
    detectedWreckages = nil
    detectedResearchData = nil
    detectedScannables = nil 
	]]
	
    local entity = Entity()
	local captain = entity.getCaptain(entity)
	
    if not captain then return end
	
    if captain.hasClass(captain,CaptainClass.SquadLeader) then
        entity:addMultiplyableBias(StatsBonuses.FighterSquads, 1)
        entity:addBaseMultiplier(StatsBonuses.ProductionCapacity, 0.1)
    end
    if captain.hasClass(captain,CaptainClass.ShieldMaster) then
        entity:addBaseMultiplier(StatsBonuses.ShieldDurability, 0.1)
        entity:addBaseMultiplier(StatsBonuses.ShieldRecharge, 0.1)
        entity:addBaseMultiplier(StatsBonuses.ShieldTimeUntilRechargeAfterHit, -0.1)
        entity:addBaseMultiplier(StatsBonuses.ShieldTimeUntilRechargeAfterDepletion, -0.1)
        entity:addBaseMultiplier(StatsBonuses.PlasmaDamage, 0.1)
    end
    if captain.hasClass(captain,CaptainClass.AICaptain) then
        entity:addMultiplyableBias(StatsBonuses.Engineers, 300)
        entity:addMultiplyableBias(StatsBonuses.Mechanics, 300)
        entity:addMultiplyableBias(StatsBonuses.AutomaticTurrets, 20)
        entity:addAbsoluteBias(StatsBonuses.GeneratedEnergy, -1000000000)
    end
    if captain.hasClass(captain,CaptainClass.LimitBreaker) then
        entity:addMultiplyableBias(StatsBonuses.ExcessProcessingPowerSteps, 2)
        entity:addMultiplyableBias(StatsBonuses.ArbitraryTurrets, 4)
        entity:addBaseMultiplier(StatsBonuses.ProductionCapacity, 0.1)
    end
    if captain.hasClass(captain,CaptainClass.StarSurfer) then
        entity:addBaseMultiplier(StatsBonuses.HyperspaceCooldown, -0.2)
        entity:addBaseMultiplier(StatsBonuses.Velocity, 0.1)
        entity:addBaseMultiplier(StatsBonuses.Acceleration, 0.1)
    end
    if captain.hasClass(captain,CaptainClass.LootGoblin) then
        entity:addBaseMultiplier(StatsBonuses.CargoHold, 0.1)
        entity:addMultiplyableBias(StatsBonuses.LootCollectionRange, 300)
    end
	--Custom Ship Bonus Perks
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpUnarmedTurrets) then
        entity:addMultiplyableBias(StatsBonuses.UnarmedTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpUnarmedTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpArmedTurrets) then
        entity:addMultiplyableBias(StatsBonuses.ArmedTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpArmedTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpPointDefenseTurrets) then
        entity:addMultiplyableBias(StatsBonuses.PointDefenseTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpPointDefenseTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpAutomaticTurrets) then
        entity:addMultiplyableBias(StatsBonuses.AutomaticTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpAutomaticTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpEnergyDamage) then
        entity:addBaseMultiplier(StatsBonuses.EnergyDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpEnergyDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpElectricDamage) then
        entity:addBaseMultiplier(StatsBonuses.ElectricDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpElectricDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpPlasmaDamage) then
        entity:addBaseMultiplier(StatsBonuses.PlasmaDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpPlasmaDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpAntiMatterDamage) then
        entity:addBaseMultiplier(StatsBonuses.AntiMatterDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpAntiMatterDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpFragmentsDamage) then
        entity:addBaseMultiplier(StatsBonuses.FragmentsDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpFragmentsDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.UpPhysicalDamage) then
        entity:addBaseMultiplier(StatsBonuses.UnarmedTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.UpPhysicalDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownUnarmedTurrets) then
        entity:addAbsoluteBias(StatsBonuses.UnarmedTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownUnarmedTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownArmedTurrets) then
        entity:addAbsoluteBias(StatsBonuses.ArmedTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownArmedTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownPointDefenseTurrets) then
        entity:addAbsoluteBias(StatsBonuses.PointDefenseTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownPointDefenseTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownAutomaticTurrets) then
        entity:addAbsoluteBias(StatsBonuses.AutomaticTurrets, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownAutomaticTurrets))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownEnergyDamage) then
        entity:addBaseMultiplier(StatsBonuses.EnergyDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownEnergyDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownElectricDamage) then
        entity:addBaseMultiplier(StatsBonuses.ElectricDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownElectricDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownPlasmaDamage) then
        entity:addBaseMultiplier(StatsBonuses.PlasmaDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownPlasmaDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownAntiMatterDamage) then
        entity:addBaseMultiplier(StatsBonuses.AntiMatterDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownAntiMatterDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownFragmentsDamage) then
        entity:addBaseMultiplier(StatsBonuses.FragmentsDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownFragmentsDamage))
	end
	if captain.hasPerk(captain,CaptainUtility.PerkType.DownPhysicalDamage) then
        entity:addBaseMultiplier(StatsBonuses.PhysicalDamage, CaptainUtility.getShipBonusPerkImpact(captain,CaptainUtility.PerkType.DownPhysicalDamage))
	end
	
end 