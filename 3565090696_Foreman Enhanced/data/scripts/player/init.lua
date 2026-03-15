package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
local player = Player()
if player then
    if onServer() then
        local hasReceivedForeman = player:getValue("foreman_system_gift")
        if not hasReceivedForeman then
            local foremanSystem = SystemUpgradeTemplate("data/scripts/systems/foremansystem.lua", Rarity(RarityType.Petty), Seed(1))
            if foremanSystem then
                local mail = Mail()
                mail.header = "Welcome to Foreman Enhanced!"
                mail.text = "Welcome to Foreman Enhanced! This mod provides advanced automated mining, salvaging, and combat fighter management for your carriers.\n\nYou've been given a basic Foreman system to get started. Install it on one of your ships to begin using automated operations.\n\nFeatures:\n• Automated mining and salvaging\n• Smart combat fighter management\n• Advanced targeting and coordination\n• Performance optimized asteroid caching\n\nEnjoy your enhanced automation experience!"
                mail.sender = "Foreman Enhanced Team"
                mail.money = 0
                mail:addItem(foremanSystem)
                player:addMail(mail)
                player:setValue("foreman_system_gift", true)
                player:sendChatMessage("Foreman", ChatMessageType.Information, "Welcome! Check your mail for a free Foreman system to get started with automated operations."%_t)
            end
        end
        -- Ensure the Foreman UI manager is attached from server so the client loads it
        player:addScriptOnce("data/scripts/ForemanManager.lua")
    end
end
