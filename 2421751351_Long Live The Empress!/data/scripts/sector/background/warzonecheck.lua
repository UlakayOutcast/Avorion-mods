local LLTE_WarZoneCheck_OnDestroyed = WarZoneCheck.onDestroyed
function WarZoneCheck.onDestroyed(destroyedId, destroyerId)

    local victim = Entity(destroyedId)
    if not victim then return end

    --Cavaliers ships should not cause a warzone. We don't care about Commune / Family ships here.
    if victim:getValue("is_cavaliers") then return end

    LLTE_WarZoneCheck_OnDestroyed(destroyedId, destroyerId)
end