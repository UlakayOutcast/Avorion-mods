package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")
include("randomext")

local SDKEntityModifier = {}

local _Elements = {
    DamageType.Physical,
    DamageType.Plasma,
    DamageType.Electric,
    DamageType.AntiMatter
}

function getOwnerIndex(name)
    local players = {Server():getOnlinePlayers()}
    
    for _, player in pairs(players) do
        if player.name == name then
            return player.index
        end
    end

    return -1

end

--[[
    m = (Method Name) The name of the calling method.
    e = (Enity) The entity being evaluated.
    l = (Log) If "1" will print the logic of the function.
    returns: true if player owned, false if not.
]]
function IsPlayerOwned(m, e, l)
    l = l or 0 -- Default Log Value
    local o = Owner(e)

    if not o then
        LogLine(m, "We couldn't find a owner.", l)
        return false
    end

    if o.isPlayer then
        LogLine(m, "Object is player owned.", l)
        return true
    end

    LogLine(m, "Object is not player owned.", l)
    return false

end

--[[
    m = (Method Name) The name of the calling method.
    e = (Enity) The entity being evaluated.
    l = (Log) If "1" will print the logic of the function.
    returns: true if alliance owned, false if not.
]]
function IsAllianceOwned(m, e, l)
    l = l or 0 -- Default Log Value
    local o = Owner(e)

    if not o then
        LogLine(m, "We couldn't find a owner.", l)
        return false
    end

    if o.isAlliance then
        LogLine(m, "Object is alliance owned.", l)
        return true
    end

    LogLine(m, "Object is not alliance owned.", l)
    return false

end

--[[
    m = (Method Name) The name of the calling method.
    i = (Index) The index of the target Alliance.
    l = (Log) If "1" will print the logic of the function.
    returns: 0 = False, 1 = True, 2 = IA Faction, 3 = Is Player
]]
function IsAllianceActive(m, i, l)
    l = l or 0
    local a = Alliance(i)

    if not a then
        LogLine(m, tostring(i) .. ", Alliance not return a valid object.", l)
        return 0
    end

    if a.isAIFaction then
        LogLine(m, tostring(a.name) .. ", Alliance is an IA Faction.", l)
        return 2
    elseif a.isPlayer then
        LogLine(m, tostring(i) .. ", Alliance returned as Player.", l)
        return 3    
    end

    local players = {Server():getOnlinePlayers()}
    
    if l == 1 then
        for key, value in pairs(players) do
            LogLine(m, "Printing Online Players - Key = " .. key .. " | Value = " .. value.name, l)
        end
    end

    for _, player in pairs(players) do 
        LogLine(m, "Check If Alliance Member: " .. tostring(player.name), l)
        if Alliance(i):contains(player.index) then
            LogLine(m, tostring(a.name) .. ", Alliance is Active (Online).", l)
            return 1
        end
    end
    
    LogLine(m, tostring(i) .. ", Alliance is not currently Active (No Members Online).", l)
    return 0

end


--[[
    m = (Method Name) The name of the calling method.
    i = (Index) The index of the target Alliance.
    l = (Log) If "1" will print the logic of the function.
    returns: True = Online, False = Offline
]]
function IsPlayerActive(m, i, l)
    l = l or 0
    local p = Player(i)
    local o = {Server():getOnlinePlayers()}

    if not p then
        LogLine(m, tostring(i) .. ", Player did not return a valid object.", l)
        return false
    end
 
    for _, player in pairs(o) do
        if player.name == p.name then
            LogLine(m, tostring(i) .. ", Player is Active (Online).", l)
            return true
        end
    end

    LogLine(m, tostring(i) .. ", Player is not currently Active (Not Online).", l)
    return false

end

------------------------------- Hull Functions --------------------------------------

-- Example: Current Max is 1.2. 
-- hullChangeDurabilityFactor(ship, true, 0.2) would equal 1.40
function hullChangeDurabilityFactor(functionname, entity, increase, change)

    if not entity then
        return false -- Change Failed
    end

    local durability = Durability(entity.id)
    if not durability then
        return false -- Change Failed
    end
    
    if not increase then
        change = -change
    end

    if change ~= 0 then
        durability.maxDurabilityFactor = durability.maxDurabilityFactor + change
    end

    return true -- Change Was Good

end

function hullCompareDurability(functionname, entity, val1, check, val2)

    if not entity then
        return false -- Change Failed
    end

    local durability = Durability(entity.id)
    if not durability then
        return false -- Change Failed
    end
    
    -- Equals
    if check == 0 then
        if val1 == val2 then return true end

    -- Greater Then
    elseif check == 1 then
        if val1 > val2 then return true end

    -- Less Than
    elseif check == 2 then
        if val1 < val2 then return true end
    end

    return false

end

------------------------------- Shield Functions --------------------------------------

-- Example: Current Max is 1.2. 
--  shieldMaxDurabilityFactor(ship, true, 0.2) would equal 1.40
function shieldMaxDurabilityFactor(functionname, entity, increase, change)

    if not entity then
        return false -- Change Failed
    end

    local shield = Shield(entity.id)
    if not shield then
        return false -- Change Failed
    end
    
    if increase then
        shield.maxDurabilityFactor = shield.maxDurabilityFactor + change
    else
        shield.maxDurabilityFactor = shield.maxDurabilityFactor - change
    end

    return true -- Change Was Good

end

function shieldImmuneToDeactivaton(functionname, entity, state)

    if not entity then
        return false -- Change Failed
    end

    local shield = Shield(entity.id)
    if not shield then
        return false -- Change Failed
    end
    
    shield.immuneToDeactivation = state

    return true -- Change Was Good

end

function shieldInvincible(functionname, entity, state)

    if not entity then
        return false -- Change Failed
    end

    local shield = Shield(entity.id)
    if not shield then
        return false -- Change Failed
    end
    
    shield.invincible = state

    return true -- Change Was Good

end

function shieldImpenetrable(functionname, entity, state)

    if not entity then
        return false -- Change Failed
    end

    local shield = Shield(entity.id)
    if not shield then
        return false -- Change Failed
    end
    
    shield.impenetrable = state

    return true -- Change Was Good

end

------------------------------- Thruster Functions --------------------------------------

function thrusterGetValue(functionname, entity, axis)

    if not entity then
        return -1 -- Failed
    end

    local thrust = Thrusters(entity.id)
    if not thrust then
        return -1 -- Failed
    end
    
    if axis == "Pitch" then
        return thrust.basePitch
    elseif axis == "Roll" then
        return thrust.baseRoll
    elseif axis == "Yaw" then
        return thrust.baseYaw
    end

    return -1 -- Failed

end

-- Example: thrusterModifyValue("Some Function", entity, "Pitch", true, 0.5)
function thrusterAddBaseMultiplier(functionname, entity, axis, increase, change)

    if not entity then
        return false -- Failed
    end

    local thrust = Thrusters(entity.id)
    if not thrust then
        return false -- Failed
    end

    if not increase then
        change = -change
    end
        
    if axis == "Pitch" then
        thrust.basePitch = thrust.basePitch + change
    elseif axis == "Roll" then
        thrust.baseRoll = thrust.baseRoll + change
    elseif axis == "Yaw" then
        thrust.baseYaw = thrust.baseYaw + change
    end

    return true -- Passed

end

------------------------------- Ship Systems Functions --------------------------------------

--[[
    m = (Method Name) The name of the calling method.
    s = (Ship System Object) The instance of the entitys Ship System
    e = (Exact) True = match exact string, False = Contains string 
    l = (Log) If "1" will print the logic of the function.
    returns: Number Installed Upgrades By Name
]]
function GetNumUpgradeByName(m, s, e, l)
    -- No Code Yet
end

--[[
    m = (Method Name) The name of the calling method.
    s = (Ship System Object) The instance of the entitys Ship System
    l = (Log) If "1" will print the logic of the function.
    returns: Number Upgrade Slots On Ship
]]
function GetSlots(m, s, l)
    -- No Code Yet
end

--[[
    m = (Method Name) The name of the calling method.
    s = (Ship System Object) The instance of the entitys Ship System
    l = (Log) If "1" will print the logic of the function.
    returns: Number Upgrade Slots On Ship
]]
function SetSlots(m, s, l)
    -- No Code Yet
end

--[[
    m = (Method Name) The name of the calling method.
    s = (Ship System Object) The instance of the entitys Ship System
    l = (Log) If "1" will print the logic of the function.
    returns: Max Number Upgrade Slots For The Ship
]]
function GetMaxSlots(m, s, l)
    -- No Code Yet
end

--[[
    m = (Method Name) The name of the calling method.
    u = (System Upgrade Templet) The upgrade we are working with.
    n = (Name) The name we are checking as a string
    l = (Log) If "1" will print the logic of the function.
    returns: True = Matches, False = Does not Match
]]
function CheckUpgradeName(m, u, n, l)
    -- No Code Yet
end

--[[
    m = (Method Name) The name of the calling method.
    u = (System Upgrade Templet) The upgrade we are working with.
    l = (Log) If "1" will print the logic of the function.
    returns: The Name or "--Failed--"
]]
function GetUpgradeName(m, u, l)
    -- No Code Yet
end

--[[
    m = (Method Name) The name of the calling method.
    u = (System Upgrade Templet) The upgrade we are working with.
    l = (Log) If "1" will print the logic of the function.
    returns: True or False
]]
function IsUpgradePermanent(m, u, l)
    -- No Code Yet
end

return SDKEntityModifier
