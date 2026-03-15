package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

FixedEnergyRequirement = true
Unique = true

function onInstalled(seed, rarity, permanent)
    if not permanent then return end
	addAbsoluteBias(StatsBonuses.Engineers, 5000)
    addAbsoluteBias(StatsBonuses.Mechanics, 5000)
    addAbsoluteBias(StatsBonuses.MinersPerTurret, -1000)
    addAbsoluteBias(StatsBonuses.MechanicsPerTurret, -1000)
    addAbsoluteBias(StatsBonuses.GunnersPerTurret, -1000)
	addAbsoluteBias(StatsBonuses.Security, 6000)
end

function onUninstalled(seed, rarity, permanent)
end

function getName()
    local name = "Lucrehulk Control Computer"
    return name
end

function getIcon(seed, rarity)
    return "data/textures/icons/droidcontrolicon.png"
end

function getPrice(seed, rarity)
    return 250000
end

function getTooltipLines(seed, rarity, permanent)
    local texts =
    {
        {ltext = "Gunners Required"%_t, rtext = "-1000", icon = CrewProfession(CrewProfessionType.Gunner).icon, boosted = permanent},
        {ltext = "Miners Required"%_t, rtext = "-1000", icon = CrewProfession(CrewProfessionType.Miner).icon, boosted = permanent},
        {ltext = "Engineer Workforce"%_t, rtext = "+5000", icon = CrewProfession(CrewProfessionType.Engineer).icon, boosted = permanent},
	    {ltext = "Mechanic Workforce"%_t, rtext = "+5000", icon = CrewProfession(CrewProfessionType.Mechanic).icon, boosted = permanent},
		{ltext = "Security Workforce"%_t, rtext = "+6000", icon = CrewProfession(CrewProfessionType.Pilot).icon, boosted = permanent},
		
    }

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getEnergy(seed, rarity, permanent)
    return 5000000000
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Roger Roger."%_t, lcolor = ColorRGB(1, 0.5, 0.5)},
        {ltext = "", boosted = permanent},
        {ltext = "This system was left over /* from a war far far away.' */"%_t, rtext = "", icon = ""},
        {ltext = "from a war far far away /* continued from 'This system was left over' */"%_t, rtext = "", icon = ""},
		{ltext = "which is capable of commanding /* continued from 'from a war far far away' */"%_t, rtext = "", icon = ""},
		{ltext = "thousands of automated droids /* continued from 'which is capable of commanding' */"%_t, rtext = "", icon = ""},
		{ltext = "that will man the ship's systems. /* continued from 'thousands of automated droids' */"%_t, rtext = "", icon = ""},
    }
end




