package.path = package.path .. ";data/scripts/lib/?.lua"
local Log = include("SDKDebugLogging")

local Debug = 0
local SDKDockingShieldExtension = "Docking Shield Extension" function GetName(n)
    return SDKDockingShieldExtension .. " - " .. n
end

function initialize() local Method = GetName("Initialize") if onClient() then return end

    local Registered = Sector():registerCallback("onShieldDamaged", "ExtededShieldDamaged")

    if Registered == 0 then
        Log.Debug(Method, "Callback Registered", Debug)
    else
        Log.Debug(Method, "Callback Failed To Register", Debug)
    end

end

function ExtededShieldDamaged(EntID, Damage, DamageType, InflicttorID) local Method = GetName("On Shield Damaged")
    Log.Debug(Method, "Evaluting Shields: " .. tostring(Entity(EntID).name), Debug)

    -- Make sure the feature is enabled. (Used for Other Developer's Mod compatibility)
    local Disabled = Entity(EntID):getValue("SDKEDSDisabled") if Disabled then return end

    -- Make sure Parent Exists and We Are Docked To It.
    local Child = Entity(EntID) if Child.type ~= EntityType.Station and Child.type ~= EntityType.Ship then return end
    local Parent = GetParent(Child)

    if CheckDocked(Parent, Child) then
        Log.Debug(Method, "Valid Parrent & Docked:" .. tostring(Child.name), Debug)
        -- Damage Parent Shields When Online When Child Has Shields.
        if IsShielded(Parent) and Child.shieldMaxDurability ~= 0 then
            Log.Debug(Method, "Is Shielded & Has Shields:" .. tostring(Child.name), Debug)            
            Child.invincible = true                                             -- Ship Can't Be Destroyed
            Child.shieldDurability = Child.shieldMaxDurability                  -- Keep Shields Topped Off
            DamageParent(Parent, Child, Damage, DamageType, InflicttorID)       -- Pass Damage To Parent Shields
            return                                                              -- Return To Keep Child Invincible
        end
    end Child.invincible = false   -- Must not be Docked or Parent Destroyed
end

function GetParent(Child) local Method = GetName("Get Parent")
    local Parent = nil if Child.dockingParent then
        Parent = Entity(Child.dockingParent)
        if Parent then Log.Debug(Method, "Parent: " .. tostring(Parent.name), Debug) end
    end return Parent
end

-- Check for Partents Shields
function IsShielded(Parent) return Parent.isShieldActive end

-- Check We Are Docked
function CheckDocked(Parent, Child)
    local Answer = false if Parent then
        Log.Debug(Method, "Check Docked: Valid Parent", Debug)
        local DockingInfo = DockingClamps(Parent)
        Answer = DockingInfo:isDocked(Child)
        if Answer == nil then Answer = false end
    end

    Log.Debug(Method, "Check Docked: " .. tostring(Answer), Debug)

    return Answer
end

function DamageParent(Parent, Child, Damage, DamageType, InflicttorID)
    Parent:damageShield(Damage, Child.translationf, InflicttorID, nil, DamageType)
end