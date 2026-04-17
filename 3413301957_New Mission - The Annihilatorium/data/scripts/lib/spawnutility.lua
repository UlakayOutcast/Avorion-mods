function SpawnUtility.addAnnihilatoriumMOTABossBuff(entity)
    if not entity or not valid(entity) then 
        return 
    end
    
    local titleName = ""
    local hpFactor = 1
    local dmgFactor = 1

    local levels = {}
    levels[1] = 3
    levels[2] = 2
    levels[3] = 1

    local level = selectByWeight(random(), levels)

    if level == 1 then
        titleName = "Hardcore "

        hpFactor = 3
        dmgFactor = 3
    elseif level == 2 then
        titleName = "Ferocious "

        hpFactor = 5
        dmgFactor = 3
    elseif level == 3 then
        titleName = "Paragon "

        hpFactor = 5
        dmgFactor = 4
    end

    --Set title
    if entity.title then
        local titleArgs = entity:getTitleArguments()
        if titleArgs then
            titleArgs.toughness = titleName
            entity:setTitleArguments(titleArgs)
        else
            entity.title = titleName .. entity.title
        end
    end

    --Set durability / damage multiplier
    local durability = Durability(entity)
    if durability then durability.maxDurabilityFactor = (durability.maxDurabilityFactor or 0) + hpFactor end

    local shield = Shield(entity)
    if shield then shield.maxDurabilityFactor = (shield.maxDurabilityFactor or 0) + hpFactor end

    if dmgFactor ~= 1 then entity.damageMultiplier = (entity.damageMultiplier or 1) * dmgFactor end

    -- increase resistances if existing
    local x, y = Sector():getCoordinates()
    local distToCenter = math.sqrt(x * x + y * y)
    SpawnUtility.applyResistanceFactorBuff(entity, level, distToCenter)    
end