local MessageManager = {}

local function getSafePlayer()
    -- CRITICAL FIX: Don't fallback to random player
    if callingPlayer == nil then
        print("Foreman: ERROR - MessageManager function called without callingPlayer")
        return nil
    end
    
    local player = Player(callingPlayer)
    if not player then
        print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
        return nil
    end
    return player
end

function MessageManager.sendAutoScanMessage()
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-scanning for asteroids..."%_t)
        end
    end
end

function MessageManager.sendAutoMineMessage()
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-mining asteroids..."%_t)
        end
    end
end

function MessageManager.sendAutoDockMessage()
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-docking fighters - sector cleared!"%_t)
        end
    end
end

function MessageManager.sendAutoDockWhenFullMessage(shipCount)
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Auto-docking fighters - " .. tostring(shipCount) .. " ship(s) cargo full!"%_t)
        end
    end
end

function MessageManager.sendSaveConfirmationMessage()
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Settings saved successfully!"%_t)
        end
    end
end
function MessageManager.sendLoadConfirmationMessage()
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Settings loaded successfully!"%_t)
        end
    end
end
function MessageManager.sendFactionMessage(factionIndex, senderName, messageType, message)
    if onServer() then
        local player = getSafePlayer()
        if player then
            player:sendChatMessage("Foreman", messageType, message)
            return
        end
    else
        local player = Player()
        if player then
            player:sendChatMessage("Foreman", messageType, message)
        end
    end
end
function MessageManager.sendForemanInfo(text)
    if not onServer() then return end
    if type(text) ~= "string" then return end
    if text:gsub("%s+", "") == "" then return end
    local player = getSafePlayer()
    if player then
        player:sendChatMessage("Foreman", ChatMessageType.Information, text)
    end
end
function MessageManager.showLoadedMessage()
    if _G.foremanLoadedMessage and onClient() then
        local player = Player()
        if player then
            player:sendChatMessage("", ChatMessageType.Information, _G.foremanLoadedMessage)
        end
    end
end
return MessageManager
