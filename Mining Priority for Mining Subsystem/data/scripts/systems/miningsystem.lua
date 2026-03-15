package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

materialLevel = 0
range = 0
amount = 0

maxMaterialLevel = 0


-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true


function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local range = 400 -- base value
    range = range + (rarity.value + 1) * 100 -- add 0 (worst rarity) to +600 (best rarity)
    range = range + math.random() * ((rarity.value/2 + 1) * 150) -- add random value between 0 (worst rarity) and 600 (best rarity)

    local material = rarity.value + 1
    -- if math.random() < 0.25 then
        -- material = material + 1
    -- end

    local amount = 3
    amount = amount + (rarity.value + 1) * 2 -- add 0 (worst rarity) to +120 (best rarity)
    amount = amount + math.random() * ((rarity.value + 1) * 5) -- add random value between 0 (worst rarity) and 60 (best rarity)

    if permanent then 
        range = range * 1.5
        amount = amount * 1.5
        material = material + 1
		if rarity.value > RarityType.Exotic then
			range = math.huge
		end
    end

    return material, range, amount
end

function onInstalled(seed, rarity, permanent)
    if onClient() and valid(Player()) then
        Player():registerCallback("onPreRenderHud", "onPreRenderHud")
    end

    materialLevel, range, amount = getBonuses(seed, rarity, permanent)

    addAbsoluteBias(StatsBonuses.ScannerMaterialReach, range)

    Entity():addScriptOnce("data/scripts/entity/utility/uncovermineablematerial.lua")
end

function onUninstalled(seed, rarity, permanent)

end

function sort(a, b)
    return a.distance < b.distance
end

function onPreRenderHud()

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret or player.state == PlayerStateType.PhotoMode then return end

    local ship = Entity()
    if player.craftIndex ~= ship.index then return end

    local shipPos = ship.translationf

    local sphere = Sphere(shipPos, range)
    local nearby = {Sector():getEntitiesByLocation(sphere)}
    local displayed = {}

    -- detect all asteroids in range
    for _, entity in pairs(nearby) do

        if entity.type == EntityType.Asteroid then
            local resources = entity:getMineableResources()
            if resources ~= nil and resources > 0 then
                local material = entity:getMineableMaterial()

                if material.value <= materialLevel then

                    local d = distance2(entity.translationf, shipPos)

                    table.insert(displayed, {material = material, asteroid = entity, distance = d})
                end
            end
        end

    end

    -- sort by distance
    table.sort(displayed, sort)

    -- display nearest x
    local renderer = UIRenderer()

    for i = 1, math.min(#displayed, amount) do
        local tuple = displayed[i]
        renderer:renderEntityTargeter(tuple.asteroid, tuple.material.color);
        renderer:renderEntityArrow(tuple.asteroid, 30, 10, 250, tuple.material.color);
    end

    renderer:display()
end

function getName(seed, rarity)
    local materialLevel, range, amount = getBonuses(seed, rarity, true)

    local classes = {}
    classes[RarityType.Legendary] = "Super-Class"%_t
    classes[RarityType.Exotic] = "Excavator-Class"%_t
    classes[RarityType.Exceptional] = "Pro-Class"%_t
    classes[RarityType.Rare] = "Miner-Class"%_t
    classes[RarityType.Uncommon] = "Advanced"%_t
    classes[RarityType.Common] = "Standard"%_t
    classes[RarityType.Petty] = "Damaged"%_t

    materialLevel = materialLevel - 1

    -- I chose to actively not translate the following strings
    local materials = {}
    materials[MaterialType.Iron] = "IR"
    materials[MaterialType.Titanium] = "TI"
    materials[MaterialType.Naonite] = "NA"
    materials[MaterialType.Trinium] = "TR"
    materials[MaterialType.Xanion] = "XA"
    materials[MaterialType.Ogonite] = "OG"
    materials[MaterialType.Avorion] = "AV"

    local name
    if materialLevel == rarity.value + 2 then
        name = "Mining Subsystem Plus"%_t
    else
        name = "Mining Subsystem"%_t
    end

    return "${class} ${material}-${name} /* ex: Advanced OG-Mining Subsystem Plus */"%_t % {class = classes[rarity.value], name = name, material = materials[materialLevel] or "IR"}
end

function getBasicName()
    return "Mining Subsystem"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/mining.png"
end

function getEnergy(seed, rarity, permanent)
    local materialLevel, range, amount = getBonuses(seed, rarity, permanent)
	-- if permanent then materialLevel = materialLevel - 1 end 
	range = math.min(range, 1500) * 0.0005 * math.max(materialLevel,1) * 1000 * 1000 * 1000 + (amount * 5 * 1000 * 1000)
    return range
end

function getPrice(seed, rarity)
    local materialLevel, range, amount = getBonuses(seed, rarity)

    return (materialLevel * 1500 + amount * 750 + range * 1.5) * 2.5 ^ (rarity.value+1)
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local bonuses = {}

    -- local materialLevel, range, amount = getBonuses(seed, rarity, permanent)
    -- materialLevel = math.max(0, math.min(materialLevel, NumMaterials() - 1))
    -- local material = Material(materialLevel)

    -- table.insert(texts, {ltext = "Material"%_t, rtext = material.name%_t, rcolor = material.color, icon = "data/textures/icons/metal-bar.png", boosted = permanent})
    -- table.insert(texts, {ltext = "Range"%_t, rtext = string.format("%g", round(range / 100, 2)), icon = "data/textures/icons/rss.png", boosted = permanent})
    -- table.insert(texts, {ltext = "Asteroids"%_t, rtext = string.format("%i", amount), icon = "data/textures/icons/rock.png", boosted = permanent})

    -- local _, rangeP, amountP = getBonuses(seed, rarity, true)
    -- table.insert(bonuses, {ltext = "Material Level"%_t, rtext = "+1", icon = "data/textures/icons/metal-bar.png"})
    -- table.insert(bonuses, {ltext = "Range"%_t, rtext = string.format("+%g", round(rangeP /3 / 100, 2)), icon = "data/textures/icons/rss.png"})
    -- table.insert(bonuses, {ltext = "Asteroids"%_t, rtext = string.format("+%i", round(amount * 0.5)), icon = "data/textures/icons/rock.png"})


    local materialLevel, range, amount = getBonuses(seed, rarity, permanent)
    materialLevel = math.max(0, math.min(materialLevel, NumMaterials() - 1))
    local material = Material(materialLevel)
    local _, rangeP, amountP = getBonuses(seed, rarity, true)

	if range and range > 0 then
        local rangeText = "Сектор"%_t
        if range < math.huge then
            rangeText = string.format("%g km", round(range / 100, 2))
        end
		table.insert(texts, {ltext = "Material"%_t, rtext = material.name%_t, rcolor = material.color, icon = "data/textures/icons/metal-bar.png", boosted = permanent})
		table.insert(texts, {ltext = "Range"%_t, rtext = rangeText, icon = "data/textures/icons/rss.png", boosted = permanent})
		table.insert(texts, {ltext = "Asteroids"%_t, rtext = string.format("%i", amount), icon = "data/textures/icons/rock.png", boosted = permanent})
    end
	if rangeP and rangeP > 0 then
        local rangeTextP = "Сектор"%_t
        if rangeP < math.huge then
            rangeTextP = string.format("%g km", round(rangeP /3 / 100, 2))
        end
		table.insert(bonuses, {ltext = "Material Level"%_t, rtext = "+1", icon = "data/textures/icons/metal-bar.png"})
		table.insert(bonuses, {ltext = "Range"%_t, rtext = rangeTextP, icon = "data/textures/icons/rss.png"})
		table.insert(bonuses, {ltext = "Asteroids"%_t, rtext = string.format("+%i", round(amountP /3)), icon = "data/textures/icons/rock.png"})
    end

	

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local texts = {}

    table.insert(texts, {ltext = "Mining System"%_t})
    table.insert(texts, {ltext = "Displays amount of resources in objects"%_t, icon = "data/textures/icons/nothing.png", fontType = FontType.Normal, lcolor = ColorRGB(0.7, 0.7, 0.7)})
    table.insert(texts, {ltext = "Highlights nearby mineable objects"%_t, icon = "data/textures/icons/nothing.png", fontType = FontType.Normal, lcolor = ColorRGB(0.7, 0.7, 0.7)})

    return texts
end

function getComparableValues(seed, rarity)
    local base = {}
    local bonus = {}

    local materialLevel, range, amount = getBonuses(seed, rarity, permanent)
    materialLevel = math.max(0, math.min(materialLevel, NumMaterials() - 1))
    local _, rangeP, amountP = getBonuses(seed, rarity, false)
	if range and range > 0 then
        local rangeText = "Сектор"%_t
        if range < math.huge then
            rangeText = string.format("%g km", round(range / 100, 2))
        end
		table.insert(base, {name = "Material"%_t, key = "material", value = materialLevel, comp = UpgradeComparison.MoreIsBetter})
		table.insert(base, {name = "Range"%_t, key = rangeText, value = round(range / 100, 2), comp = UpgradeComparison.MoreIsBetter})
		table.insert(base, {name = "Asteroids"%_t, key = "asteroids", value = round(amount), comp = UpgradeComparison.MoreIsBetter})
    end
	if rangeP and rangeP > 0 then
        local rangeTextP = "Сектор"%_t
        if rangeP < math.huge then
            rangeTextP = string.format("%g km", round(rangeP /3 / 100, 2))
        end
		table.insert(bonus, {name = "Material Level"%_t, key = "material", value = 1, comp = UpgradeComparison.MoreIsBetter})
		table.insert(bonus, {name = "Range"%_t, key = rangeTextP, value = round(rangeP /3 / 100, 2), comp = UpgradeComparison.MoreIsBetter})
		table.insert(bonus, {name = "Asteroids"%_t, key = "asteroids", value = round(amountP /3), comp = UpgradeComparison.MoreIsBetter})
    end



    return base, bonus
end
