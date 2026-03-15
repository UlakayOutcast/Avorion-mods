local ESCC_WarZoneCheck_OnDestroyed = WarZoneCheck.onDestroyed
function WarZoneCheck.onDestroyed(destroyedId, destroyerId)
    local victim = Entity(destroyedId)
    if not victim then return end

    --Designated ships should not cause a warzone.
    if victim:getValue("_ESCC_bypass_hazard") then return end

    ESCC_WarZoneCheck_OnDestroyed(destroyedId, destroyerId)
end