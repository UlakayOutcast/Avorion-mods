local DeferredCallbackManager = {}

function DeferredCallbackManager.onSystemsChanged_player(shipId)
    deferredCallback(0.1, "deferredOnSystemsChanged_player", shipId)
end

return DeferredCallbackManager
