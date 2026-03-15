local GlobalCallbackManager = {}
function GlobalCallbackManager.onJump(shipId, fm)
    if fm.onJump then fm.onJump(shipId) end
end
return GlobalCallbackManager
