local ForemanInfoMessageManager = {}

function ForemanInfoMessageManager.sendForemanInfo(text)
    if not onServer() then return end
    if type(text) ~= "string" then return end
    if text:gsub("%s+", "") == "" then return end
    
    local player = Player(callingPlayer)
    if player then
        player:sendChatMessage("Foreman", ChatMessageType.Information, text)
    end
end

return ForemanInfoMessageManager
