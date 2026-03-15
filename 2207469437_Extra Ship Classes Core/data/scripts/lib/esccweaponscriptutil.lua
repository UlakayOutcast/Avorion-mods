package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")

local ESCCWeaponScriptUtil = {}
local self = ESCCWeaponScriptUtil

self._Debug = 0
self._DebugLevel = 1

function ESCCWeaponScriptUtil.getEnemiesInSector(_sector, factionIdx)
    _sector = _sector or Sector()

    local rawEnemies = { _sector:getEnemies(factionIdx) }
    local enemies = {}
    for _, rawEnemy in pairs(rawEnemies) do
        if rawEnemy.type == EntityType.Ship or rawEnemy.type == EntityType.Station then
            table.insert(enemies, rawEnemy)
        end
    end

    return enemies
end

function ESCCWeaponScriptUtil.pickTargetFromTable(targetTbl, allowInvincibleTarget)
    local methodName = "Pick Target From Table"

    local chosenCandidate = nil
    local attempts = 0

    self.Log(methodName, "Found at least one suitable target. Picking a random one.", 1)

    while not chosenCandidate and attempts < 10 do
        local randomPick = randomEntry(targetTbl)
        if self.isTargetInvincibleCheck(randomPick, allowInvincibleTarget) then
            chosenCandidate = randomPick
        end
        attempts = attempts + 1
    end

    if not chosenCandidate then
        self.Log(methodName, "Could not find a non-invincible target in 10 tries - picking one at random.", 1)
        chosenCandidate = randomEntry(targetTbl)
    end

    return chosenCandidate
end

function ESCCWeaponScriptUtil.isTargetXsotanCheck(target)
    local xsotanTags = {
        "is_xsotan",
        "xsotan_summoner_minion",
        "xsotan_master_summoner_minion", --We're unlikely to see these, but hey! you never know.
        "xsotan_revenant"
    }

    for idx, tag in pairs(xsotanTags) do
        if target:getValue(tag) then
            return true
        end
    end

    return false
end

function ESCCWeaponScriptUtil.isTargetInvincibleCheck(target, allowInvincibleTarget)
    if allowInvincibleTarget or not target.invincible then
        return true
    else
        return false
    end
end

function ESCCWeaponScriptUtil.inflictDamageToTarget(target, damage, damageType, inflictorID)
    local methodName = "Inflict Damage To Target"

    local shields = Shield(target)
    local durability = Durability(target)

    if shields then
        local shieldDamage = damage
        local hullDamage = 0
        if shields.durability < damage then
            shieldDamage = shields.durability
            hullDamage = damage - shieldDamage
        end
        self.Log(methodName, "Inflicting " .. tostring(shieldDamage) .. " damage to shield and " .. tostring(hullDamage) .. " to " .. tostring(target.name) .. " hull.")
        shields:inflictDamage(shieldDamage, DamageSource.Weaponry, damageType, target.translationf, inflictorID)
        if hullDamage > 0 then
            durability:inflictDamage(hullDamage, DamageSource.Weaponry, damageType, inflictorID)
        end
    else
        if durability then
            durability:inflictDamage(damage, DamageSource.Weaponry, damageType, inflictorID)
        end
    end
end

--region #LOGGING

function ESCCWeaponScriptUtil.Log(methodName, msg, debugLevel)
    debugLevel = debugLevel or 1
    if self._Debug == 1 and debugLevel >= self._DebugLevel then
        print("[ESCC Weapon Utility] - [" .. methodName .. "] - " .. msg)
    end
end

--endregion

return ESCCWeaponScriptUtil