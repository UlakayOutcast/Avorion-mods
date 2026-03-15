local attachAndInteract_ESCC = AttachDebugScript.attachAndInteract
function AttachDebugScript.attachAndInteract(entityId)
    local entity = Entity(entityId)
    if not entity then return end
    if not GameSettings().devMode then return end

    entity:addScriptOnce("lib/esccdbg.lua")

    attachAndInteract_ESCC(entityId)
end