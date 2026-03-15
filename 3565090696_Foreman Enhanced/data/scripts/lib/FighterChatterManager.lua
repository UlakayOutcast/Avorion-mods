local FighterChatterManager = {}

-- Fighter chatter cooldown tracking
local _fighterChatterCooldowns = {}
local _fighterChatterCooldownTime = 5 -- 5 seconds cooldown between chatter messages

function FighterChatterManager.fighterChatterMessage(fighterId, message)
    if not fighterId or not message then return end
    
    local now = appTime()
    local fighterIdString = tostring(fighterId)
    local lastChatterTime = _fighterChatterCooldowns[fighterIdString]
    
    -- Check if enough time has passed since last chatter
    if lastChatterTime and (now - lastChatterTime) < _fighterChatterCooldownTime then
        return -- Skip this chatter due to cooldown
    end
    
    -- Update the last chatter time and send the message
    _fighterChatterCooldowns[fighterIdString] = now
    Sector():broadcastChatMessage(Entity(fighterId), ChatMessageType.Chatter, message)
end

return FighterChatterManager
