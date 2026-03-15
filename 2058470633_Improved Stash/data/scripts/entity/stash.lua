include("utility")

local RewardType = {
    Money = 0,
    Resource = 1,
    Turrent = 2,
    Upgrade = 3
}

function receiveMoney(faction)
    local x, y = Sector():getCoordinates()
    local bonusMultiplier = getBonusMultiplier()

    local scaledReward = getSectorRewardValue(x, y, RewardType.Money)
    local money = scaledReward * bonusMultiplier
    Sector():dropBundle(Entity().translationf, faction, nil, money)

    scaledReward = getSectorRewardValue(x, y, RewardType.Resource)
    local resources = scaledReward * bonusMultiplier
    local material = getMaterialType(x, y)
    Sector():dropResources(Entity().translationf, faction, nil, material, resources)
end

function getMaterialType(x, y)
    local probabilities = Balancing_GetMaterialProbability(x, y)
    return Material(getValueFromDistribution(probabilities))
end

function getSectorRewardValue(x, y, rewardType)
    local sigmoid_vars                = {}
    sigmoid_vars[RewardType.Money]    = { min = 50000, max = 1500000, optimal_dist = 250, bias_start = 0.016405753, bias_mean = 0.951090399 }
    sigmoid_vars[RewardType.Resource] = { min = 5000, max = 25000, optimal_dist = 250, bias_start = 0.010683913, bias_mean = 1.999999997 }


    local distance = math.sqrt((x ^ 2) + (y ^ 2))
    return calculateSectorRewardFactor(distance, sigmoid_vars[rewardType])
end

function calculateSectorRewardFactor(distance, s_args)
    local factor = s_args.max -
        (s_args.max - s_args.min) *
        1 / ((1 + math.exp(-s_args.bias_start * (distance - s_args.optimal_dist))) ^ s_args.bias_mean)

    return factor
end

function getBonusMultiplier()
    local probability = random():getFloat()
    local multiplier = 1.0

    if probability < 0.005 then
        multiplier = 10.0
    elseif probability < 0.1 then
        multiplier = 3.0
    elseif probability < 0.25 then
        multiplier = 1.5
    end

    return multiplier
end

function getDropRarity()
    local rarity = Rarity(RarityType.Exceptional)
    local probability = random():getFloat()

    if probability < 0.005 then
        rarity = Rarity(RarityType.Legendary)
    elseif probability < 0.05 then
        rarity = Rarity(RarityType.Exotic)
    elseif probability >= 0.7 then
        rarity = Rarity(RarityType.Rare)
    end

    return rarity
end

function getTechOffsetDistance(x, y)
    local techOffset = 2
    local probability = random():getFloat()
    if probability < 0.005 then
        techOffset = 7
    elseif probability < 0.10 then
        techOffset = 5
    end

    -- Safety check to prevent offset from causing negative calculations in the generator
    local offsetLimit = length(vec2(x, y)) / 10
    techOffset = math.min(offsetLimit, techOffset)
    return (-techOffset * 10)
end

function receiveTurret(faction)
    local x, y = Sector():getCoordinates()

    local generator = SectorTurretGenerator()
    generator.minRarity = getDropRarity()

    local techOffset = getTechOffsetDistance(x, y)
    local turret = generator:generate(x, y, techOffset)
    Sector():dropTurret(Entity().translationf, faction, nil, turret)
end

function receiveUpgrade(faction)
    local x, y = Sector():getCoordinates()

    local generator = UpgradeGenerator()
    generator.minRarity = getDropRarity()

    if faction.isPlayer and faction.ownsBlackMarketDLC then
        generator.blackMarketUpgradesEnabled = true
    end

    if faction.isPlayer and faction.ownsIntoTheRiftDLC then
        generator.intoTheRiftUpgradesEnabled = true
    end

    local upgrade = generator:generateSectorSystem(x, y)
    Sector():dropUpgrade(Entity().translationf, faction, nil, upgrade)
end
