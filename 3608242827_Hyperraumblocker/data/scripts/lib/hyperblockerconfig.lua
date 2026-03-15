local HyperblockerConfig = {}

-- Avorion distance units: 100 units = 1 km
HyperblockerConfig.rarityOrder = {
    {id = RarityType.Common,       name = "Gewöhnlich",      range = 1000},  -- 10 km
    {id = RarityType.Uncommon,     name = "Außergewöhnlich", range = 2000},  -- 20 km
    {id = RarityType.Rare,         name = "Selten",          range = 3000},  -- 30 km
    {id = RarityType.Exceptional,  name = "Exzeptionell",    range = 4000},  -- 40 km
    {id = RarityType.Exotic,       name = "Exotisch",        range = 5000},  -- 50 km
    {id = RarityType.Legendary,    name = "Legendär",        range = 6000},  -- 60 km
}

HyperblockerConfig.rangeByRarity = {}
for _, entry in ipairs(HyperblockerConfig.rarityOrder) do
    HyperblockerConfig.rangeByRarity[entry.id] = entry.range
end

HyperblockerConfig.unitsPerKilometer = 100

-- Stromverbrauch pro Seltenheit (Watt)
HyperblockerConfig.energyByRarity = {
    [RarityType.Common]      = 100  * 1000 * 1000 * 1000,  -- 100 GW
    [RarityType.Uncommon]    = 215 * 1000 * 1000 * 1000,  -- 215 GW
    [RarityType.Rare]        = 350 * 1000 * 1000 * 1000,  -- 350 GW
    [RarityType.Exceptional] = 500 * 1000 * 1000 * 1000,  -- 500 GW
    [RarityType.Exotic]      = 800 * 1000 * 1000 * 1000,  -- 800 GW
    [RarityType.Legendary]   = 1200 * 1000 * 1000 * 1000,  -- 1200 GW
}

-- Fallback-Werte für den alten linearen Ansatz
HyperblockerConfig.energyBase = 0
HyperblockerConfig.energyPerKm = 0
HyperblockerConfig.priceBase = 850000
HyperblockerConfig.pricePerRarity = 975000

-- Debug-Flag: bei true schreibt das Systemskript Statusupdates in das Server-Log
HyperblockerConfig.debugLogging = false

-- Gewichtung im UpgradeGenerator (z.B. 5.0 für maximale Testchance)
HyperblockerConfig.generatorWeight = 0.5

HyperblockerConfig.equipmentDock = {
    guaranteedSlot = false, -- Optionaler garantierter Shop-Slot (default aus)
    rngReplacementChance = 0.03-- % Chance, dass ein Shop-Item ersetzt wird
}

return HyperblockerConfig
