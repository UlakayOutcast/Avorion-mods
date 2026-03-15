package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("utility")
include ("randomext")
include ("faction")
include ("stringutility")
include ("weapontype")
local ShopAPI = include ("shop")
local SectorTurretGenerator = include ("sectorturretgenerator")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace CavTurretMerchant
CavTurretMerchant = {}
CavTurretMerchant = ShopAPI.CreateNamespace()
CavTurretMerchant.interactionThreshold = 0

CavTurretMerchant.rarityFactors = {}
CavTurretMerchant.rarityFactors[-1] = 1.0
CavTurretMerchant.rarityFactors[0] = 1.0
CavTurretMerchant.rarityFactors[1] = 1.0
CavTurretMerchant.rarityFactors[2] = 1.0
CavTurretMerchant.rarityFactors[3] = 1.0 --Can't be higher than exceptional or we can't buy it due to the fact that you can't technically ally the cavaliers.
CavTurretMerchant.rarityFactors[4] = 0.0
CavTurretMerchant.rarityFactors[5] = 0.0

CavTurretMerchant.specialOfferRarityFactors = {}
CavTurretMerchant.specialOfferRarityFactors[-1] = 0.0
CavTurretMerchant.specialOfferRarityFactors[0] = 0.0
CavTurretMerchant.specialOfferRarityFactors[1] = 0.0
CavTurretMerchant.specialOfferRarityFactors[2] = 1.0
CavTurretMerchant.specialOfferRarityFactors[3] = 1.0
CavTurretMerchant.specialOfferRarityFactors[4] = 0.0
CavTurretMerchant.specialOfferRarityFactors[5] = 0.0

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function CavTurretMerchant.interactionPossible(playerIndex, option)
    local _Player = Player(playerIndex)
    local _Rank = _Player:getValue("_llte_cavaliers_ranklevel")
    if _Rank and _Rank >= 2 then
        return true
    else
        return false
    end
end

local function comp(a, b)
    local ta = a.turret;
    local tb = b.turret;

    if ta.rarity.value == tb.rarity.value then
        if ta.material.value == tb.material.value then
            return ta.weaponPrefix < tb.weaponPrefix
        else
            return ta.material.value > tb.material.value
        end
    else
        return ta.rarity.value > tb.rarity.value
    end
end

function CavTurretMerchant.shop:addItems()

    -- simply init with a 'random' seed
    local station = Entity()

    local _Paladin = station:getValue("_llte_PaladinInventory")

    -- create all turrets
    local turrets = {}

    local x, y = Sector():getCoordinates()
    local generator = SectorTurretGenerator()
    generator.rarities = generator:getSectorRarityDistribution(x, y)

    for i, rarity in pairs(generator.rarities) do
        generator.rarities[i] = rarity * CavTurretMerchant.rarityFactors[i] or 1
    end

    local _Offset = -20
    if _Paladin then
        _Offset = -25
    end

    for i = 1, 13 do
        local turret = InventoryTurret(generator:generate(x, y, _Offset))
        local amount = 1
        if i == 1 then
            turret = InventoryTurret(generator:generate(x, y, _Offset, nil, WeaponType.MiningLaser))
            amount = 2
        elseif i == 2 then
            turret = InventoryTurret(generator:generate(x, y, _Offset, nil, WeaponType.PointDefenseChainGun))
            amount = 2
        elseif i == 3 then
            turret = InventoryTurret(generator:generate(x, y, _Offset, nil, WeaponType.ChainGun))
            amount = 2
        end

        local pair = {}
        pair.turret = turret
        pair.amount = amount

        if turret.rarity.value == 1 then -- uncommon weapons may be more than one
            if math.random() < 0.3 then
                pair.amount = pair.amount + 1
            end
        elseif turret.rarity.value == 0 then -- common weapons may be some more than one
            if math.random() < 0.5 then
                pair.amount = pair.amount + 1
            end
            if math.random() < 0.5 then
                pair.amount = pair.amount + 1
            end
        end

        table.insert(turrets, pair)
    end

    table.sort(turrets, comp)

    for _, pair in pairs(turrets) do
        CavTurretMerchant.shop:add(pair.turret, pair.amount)
    end
end

-- sets the special offer that gets updated every 20 minutes
function CavTurretMerchant.shop:onSpecialOfferSeedChanged()
    local station = Entity()

    local _Paladin = station:getValue("_llte_PaladinInventory")

    local generator = SectorTurretGenerator(CavTurretMerchant.shop:generateSeed())

    local x, y = Sector():getCoordinates()
    local rarities = generator:getSectorRarityDistribution(x, y)

    local _Offset = -24
    if _Paladin then
        _Offset = -36
    end

    for i, rarity in pairs(rarities) do
        rarities[i] = rarity * CavTurretMerchant.specialOfferRarityFactors[i] or 1
    end

    generator.rarities = rarities

    local specialOfferTurret = InventoryTurret(generator:generate(x, y, _Offset))
    CavTurretMerchant.shop:setSpecialOffer(specialOfferTurret)
end

function CavTurretMerchant.initialize()

    local station = Entity()
    if station.title == "" then
        station.title = "Turret Merchant"%_t
    end

    CavTurretMerchant.shop:initialize(station.translatedTitle)

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/turret.png"
    end

    if onServer() then
        local _Paladin = station:getValue("_llte_PaladinInventory")

        if _Paladin then
            CavTurretMerchant.rarityFactors[-1] = 0.0 --Petty
            CavTurretMerchant.rarityFactors[0] = 0.5  --Common
            CavTurretMerchant.rarityFactors[1] = 0.75  --Uncommon
            CavTurretMerchant.rarityFactors[2] = 0.75  --Rare

            CavTurretMerchant.specialOfferRarityFactors[2] = 0.5 --Rare
        end
    end
end

function CavTurretMerchant.initUI()
    local station = Entity()
    CavTurretMerchant.shop:initUI("Trade Equipment"%_t, station.translatedTitle, "Turrets"%_t, "data/textures/icons/bag_turret.png")
end
