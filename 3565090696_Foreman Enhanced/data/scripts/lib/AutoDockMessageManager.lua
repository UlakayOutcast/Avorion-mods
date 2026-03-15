local AutoDockMessageManager = {}

function AutoDockMessageManager.sendAutoDockMessage()
    if onServer() then
        local player = Player(callingPlayer)
        if player then
            player:sendChatMessage("", ChatMessageType.Normal, "Auto-dock activated! Recalling all fighters."%_t)
        end
    end
end

return AutoDockMessageManager
