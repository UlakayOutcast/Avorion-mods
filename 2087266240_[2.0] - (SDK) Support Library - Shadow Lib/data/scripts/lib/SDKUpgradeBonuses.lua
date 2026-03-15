package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")
include("randomext")
include("SDKDebugLogging")

local SDKUpgradebonuses = {}

local _Elements = {
    DamageType.Physical,
    DamageType.Plasma,
    DamageType.Electric,
    DamageType.AntiMatter
}

--[[
    Simple function to count the legnth of a table.
    t = (Table) The table being counted.
    Return: Number of items in the table.
]]
function TableLegnth(t)

    if not t then return 0 end

    local c = 0 for _ in pairs(t) do 
        c = c + 1 end
    return c

end

--[[
    Returns a number of bonuses based on rarity.
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    r1 - r5 = (Rarity High Value) The max number that rarity level can return.
    l = (Log) If "1" will print the logic of the function.    
    returns: Rarity based bonus number.
]]
function GetNumberOfBonuses(m, v, s, r5, r4, r3, r2, r1, l)
    
    l = l or 0 math.randomseed(s)

    local b = 0                              -- Petty/Common Upgrade
    if v >= 5 then b = getInt(0, r5)         -- Legendary Upgrade
    elseif v == 4 then b = getInt(0, r4)     -- Exotic Upgrade
    elseif v == 3 then b = getInt(0, r3)     -- Exceptional Upgrade
    elseif v == 2 then b = getInt(0, r2)     -- Rare Upgrade
    elseif v == 1 then b = getInt(0, r1) end -- Uncommon Upgrade    
    
    return b

end

--[[
    Returns a number of bonuses based on rarity.
    m  = (Method Name) The name of the calling method.
    v  = (Rarity Value) The Rarity Level
    s  = (Seed) The random seed being used.
    eb - (Enabled Bonuses) List we are adding to and returning.
    rf = (Rarity Floor) The lowest rarity level that the function will run for.
    n  = (Number) Number of Bonuses to pick.
    b  = (Bonuses) List we are going to pick from randomly.
    l  = (Log) If "1" will print the logic of the function.    
    returns: Rarity based bonus number.
]]
function AddEnabledBonuses(m, v, s, eb, rf, n, lb, l)
    
    math.randomseed(s)

    -- Check Table Legnth Isn't Shorter Than Requested Bonuses.
    local tl = TableLegnth(lb) 

    -- If Table Is Shorter Then Requested. Set Requested to Table Legnth
    if tl < n then 
        n = tl LogLine(m, "(Get Enabled Bonuses) Table was shorter than the requested number of bonuses.", l)
    end 

    -- Selet Bonuses
    if v >= rf and n ~= 0 then             
        for i = 1, n do                                   -- Loop and Grab "n" number of Bonuses      
            local perk = selectByWeight(random(), lb)    
            eb[perk] = 1                                  -- Add To Enabled
            lb[perk] = nil                                -- Remove From Selectable Items
        end
    end

    return eb -- return enabled bonuses

end

--[[
    Small perk bonus. Not the large Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetEngineerEfficiencyPerk(m, v, s, l)
    
    l = l or 0 math.randomseed(s)

    local e = 0 if v >= 5 then e = math.random(10, 64)       -- Legendary Upgrade
    elseif v == 4 then e = math.random(10, 50)               -- Exotic Upgrade
    elseif v == 3 then e = math.random(10, 40)               -- Exceptional Upgrade
    elseif v == 2 then e = math.random(10, 30)               -- Rare Upgrade
    elseif v == 1 then e = math.random(10, 20)               -- Uncommon Upgrade
    elseif v == 0 then e = 0                                 -- Common Upgrade
    elseif v == -1 then e = 0 end                            -- Petty Upgrade
        
    return e / 1000 -- Max 6%, Min 1% or 0

end

--[[
    Small perk bonus. Not the large Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetMechanicsEfficiencyPerk(m, v, s, l)
    
    l = l or 0 math.randomseed(s)

    local e = 0 if v >= 5 then e = math.random(10, 64)       -- Legendary Upgrade
    elseif v == 4 then e = math.random(10, 50)               -- Exotic Upgrade
    elseif v == 3 then e = math.random(10, 40)               -- Exceptional Upgrade
    elseif v == 2 then e = math.random(10, 30)               -- Rare Upgrade
    elseif v == 1 then e = math.random(10, 20)               -- Uncommon Upgrade
    elseif v == 0 then e = 0                                 -- Common Upgrade
    elseif v == -1 then e = 0 end                            -- Petty Upgrade
        
    return e / 1000 -- Max 6%, Min 1% or 0

end

--[[
    Small perk bonus. Not the large Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetMinersEfficiencyPerk(m, v, s, l)
    
    l = l or 0 math.randomseed(s)

    local e = 0 if v >= 5 then e = math.random(10, 64)       -- Legendary Upgrade
    elseif v == 4 then e = math.random(10, 50)               -- Exotic Upgrade
    elseif v == 3 then e = math.random(10, 40)               -- Exceptional Upgrade
    elseif v == 2 then e = math.random(10, 30)               -- Rare Upgrade
    elseif v == 1 then e = math.random(10, 20)               -- Uncommon Upgrade
    elseif v == 0 then e = 0                                 -- Common Upgrade
    elseif v == -1 then e = 0 end                            -- Petty Upgrade
        
    return e / 1000 -- Max 6%, Min 1% or 0

end

--[[
    Large perk bonus. Standard (Main attribute) Bonus.
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetMinersEfficiencyBonus(m, v, s, l)
    
    l = l or 0 math.randomseed(s)

    local e = 0 if v >= 5 then e = math.random(12, 30)       -- Legendary Upgrade
    elseif v == 4 then e = math.random(10, 25)               -- Exotic Upgrade
    elseif v == 3 then e = math.random(8, 20)                -- Exceptional Upgrade
    elseif v == 2 then e = math.random(6, 15)                -- Rare Upgrade
    elseif v == 1 then e = math.random(4, 10)                -- Uncommon Upgrade
    elseif v == 0 then e = 0                                 -- Common Upgrade
    elseif v == -1 then e = 0 end                            -- Petty Upgrade
        
    return e / 100 -- Max 30%, Min 4% or 0

end

--[[
    Small perk bonus. Not the large Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetGunnersEfficiencyPerk(m, v, s, l)
    
    l = l or 0 math.randomseed(s)

    local e = 0 if v >= 5 then e = math.random(10, 64)       -- Legendary Upgrade
    elseif v == 4 then e = math.random(10, 50)               -- Exotic Upgrade
    elseif v == 3 then e = math.random(10, 40)               -- Exceptional Upgrade
    elseif v == 2 then e = math.random(10, 30)               -- Rare Upgrade
    elseif v == 1 then e = math.random(10, 20)               -- Uncommon Upgrade
    elseif v == 0 then e = 0                                 -- Common Upgrade
    elseif v == -1 then e = 0 end                            -- Petty Upgrade
        
    return e / 1000 -- Max 6%, Min 1% or 0

end

--[[
    Small perk bonus. Not the large Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetTurretPerk(m, v, s, l)
    
    l = l or 0 math.randomseed(s)

    local e = 0 if v >= 5 then e = math.random(1, 4)       -- Legendary Upgrade
    elseif v == 4 then e = math.random(1, 3)               -- Exotic Upgrade
    elseif v == 3 then e = math.random(1, 2)               -- Exceptional Upgrade
    elseif v == 2 then e = math.random(1, 2)               -- Rare Upgrade
    elseif v == 1 then e = 1                               -- Uncommon Upgrade
    elseif v == 0 then e = 0                               -- Common Upgrade
    elseif v == -1 then e = 0 end                          -- Petty Upgrade
        
    return e -- Max 4, Min 1

end

--[[
    Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetTurretStandard(m, v, l)
    
    l = l or 0 

    if v >= 5 then return 6                                   -- Legendary Upgrade
    elseif v == 4 then return 5                               -- Exotic Upgrade
    elseif v == 3 then return 4                               -- Exceptional Upgrade
    elseif v == 2 then return 3                               -- Rare Upgrade
    elseif v == 1 then return 2                               -- Uncommon Upgrade
    elseif v == 0 then return 1                               -- Common Upgrade
    elseif v == -1 then return 1 end                          -- Petty Upgrade

end

--[[
    Permanent Install Bonus for the Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetTurretBonus(m, v, l)
    
    l = l or 0 

    if v >= 5 then return 3                                   -- Legendary Upgrade
    elseif v == 4 then return 2                               -- Exotic Upgrade
    elseif v == 3 then return 2                               -- Exceptional Upgrade
    elseif v == 2 then return 1                               -- Rare Upgrade
    elseif v == 1 then return 1                               -- Uncommon Upgrade
    elseif v == 0 then return 1                               -- Common Upgrade
    elseif v == -1 then return 1 end                          -- Petty Upgrade

end

--[[
    Small perk bonus. Not the large Standard (Main attribute) Bonus
    m = (Method Name) The name of the calling method.
    v = (Rarity Value) The Rarity Level
    s = (Seed) The random seed being used.
    l = (Log) If "1" will print the logic of the function.
    returns: Rarity based perk value
]]
function GetGeneratedEnergyPerk(m, v, s, l)
    
    l = l or 0 math.randomseed(s)
    
    local e = 0 if v >= 5 then e = math.random(1, 20)        -- Legendary Upgrade
    elseif v == 4 then e = math.random(1, 16)                -- Exotic Upgrade
    elseif v == 3 then e = math.random(1, 12)                -- Exceptional Upgrade
    elseif v == 2 then e = math.random(1, 8)                 -- Rare Upgrade
    elseif v == 1 then e = math.random(1, 4)                 -- Uncommon Upgrade
    elseif v == 0 then e = 0                                 -- Common Upgrade
    elseif v == -1 then e = 0 end                            -- Petty Upgrade
        
    return e / 100 -- Max 20%, Min 1% or 0

end

return SDKUpgradebonuses
