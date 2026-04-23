-- Assign opposing perks, not sure why this function gets niled out at the end
local function addOpposingPerk(a, b)
    if not opposingPerks[a] then
        opposingPerks[a] = {}
    end

    if not opposingPerks[b] then
        opposingPerks[b] = {}
    end

    table.insert(opposingPerks[a], b)
    table.insert(opposingPerks[b], a)
end
addOpposingPerk(CaptainUtility.PerkType.Hodophile, CaptainUtility.PerkType.Hodophobic)
addOpposingPerk(CaptainUtility.PerkType.Friendly, CaptainUtility.PerkType.Unfriendly)
addOpposingPerk(CaptainUtility.PerkType.UpUnarmedTurrets, CaptainUtility.PerkType.DownUnarmedTurrets)
addOpposingPerk(CaptainUtility.PerkType.UpArmedTurrets, CaptainUtility.PerkType.DownArmedTurrets)
addOpposingPerk(CaptainUtility.PerkType.UpPointDefenseTurrets, CaptainUtility.PerkType.DownPointDefenseTurrets)
addOpposingPerk(CaptainUtility.PerkType.UpAutomaticTurrets, CaptainUtility.PerkType.DownAutomaticTurrets)
addOpposingPerk(CaptainUtility.PerkType.UpEnergyDamage, CaptainUtility.PerkType.DownEnergyDamage)
addOpposingPerk(CaptainUtility.PerkType.UpElectricDamage, CaptainUtility.PerkType.DownElectricDamage)
addOpposingPerk(CaptainUtility.PerkType.UpPlasmaDamage, CaptainUtility.PerkType.DownPlasmaDamage)
addOpposingPerk(CaptainUtility.PerkType.UpAntiMatterDamage, CaptainUtility.PerkType.DownAntiMatterDamage)
addOpposingPerk(CaptainUtility.PerkType.UpFragmentsDamage, CaptainUtility.PerkType.DownFragmentsDamage)
addOpposingPerk(CaptainUtility.PerkType.UpPhysicalDamage, CaptainUtility.PerkType.DownPhysicalDamage)
addOpposingPerk = nil

-- Append to Possible Perks function
local ExtCapts_CaptainGenerator_getPossiblePerks = CaptainGenerator.getPossiblePerks
function CaptainGenerator.getPossiblePerks()
	local positive, negative, neutral = {}
    if ExtCapts_CaptainGenerator_getPossiblePerks then
        positive, negative, neutral = ExtCapts_CaptainGenerator_getPossiblePerks()
    end
	
	table.insert(positive, CaptainUtility.PerkType.Hodophile)
	table.insert(positive, CaptainUtility.PerkType.Friendly)
	table.insert(positive, CaptainUtility.PerkType.UpUnarmedTurrets)
	table.insert(positive, CaptainUtility.PerkType.UpArmedTurrets)
	table.insert(positive, CaptainUtility.PerkType.UpPointDefenseTurrets)
	table.insert(positive, CaptainUtility.PerkType.UpAutomaticTurrets)
	table.insert(positive, CaptainUtility.PerkType.UpEnergyDamage)
	table.insert(positive, CaptainUtility.PerkType.UpElectricDamage)
	table.insert(positive, CaptainUtility.PerkType.UpPlasmaDamage)
	table.insert(positive, CaptainUtility.PerkType.UpAntiMatterDamage)
	table.insert(positive, CaptainUtility.PerkType.UpFragmentsDamage)
	table.insert(positive, CaptainUtility.PerkType.UpPhysicalDamage)
	
	table.insert(negative, CaptainUtility.PerkType.Hodophobic)
	table.insert(negative, CaptainUtility.PerkType.Unfriendly)
	table.insert(negative, CaptainUtility.PerkType.DownUnarmedTurrets)
	table.insert(negative, CaptainUtility.PerkType.DownArmedTurrets)
	table.insert(negative, CaptainUtility.PerkType.DownPointDefenseTurrets)
	table.insert(negative, CaptainUtility.PerkType.DownAutomaticTurrets)
	table.insert(negative, CaptainUtility.PerkType.DownEnergyDamage)
	table.insert(negative, CaptainUtility.PerkType.DownElectricDamage)
	table.insert(negative, CaptainUtility.PerkType.DownPlasmaDamage)
	table.insert(negative, CaptainUtility.PerkType.DownAntiMatterDamage)
	table.insert(negative, CaptainUtility.PerkType.DownFragmentsDamage)
	table.insert(negative, CaptainUtility.PerkType.DownPhysicalDamage)
	
    return positive, negative, neutral
end