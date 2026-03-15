local SaveConfirmationManager = {}

function SaveConfirmationManager.sendSaveConfirmationMessage()
    if onServer() then
        -- CRITICAL FIX: Don't fallback to random player
        if callingPlayer == nil then
            print("Foreman: ERROR - sendSaveConfirmationMessage called without callingPlayer")
            return
        end
        
        local player = Player(callingPlayer)
        if not player then
            print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
            return
        end
        
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Automation settings saved")
        end
    end
end

function SaveConfirmationManager.sendLoadConfirmationMessage()
    if onServer() then
        -- CRITICAL FIX: Don't fallback to random player
        if callingPlayer == nil then
            print("Foreman: ERROR - sendLoadConfirmationMessage called without callingPlayer")
            return
        end
        
        local player = Player(callingPlayer)
        if not player then
            print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
            return
        end
        
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Automation settings loaded from save")
        end
    end
end

return SaveConfirmationManager
