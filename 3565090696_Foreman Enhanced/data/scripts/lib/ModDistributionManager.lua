local ModDistributionManager = {}
function ModDistributionManager.checkAndDistributeModFiles(player, sendModFilesToClientCallback)
    if onServer() then
        local clientModVersion = player:getValue("foreman_mod_version")
        local serverModVersion = "2.1.0" -- Update this when you make changes
        if not clientModVersion or clientModVersion ~= serverModVersion then
            player:sendChatMessage("Foreman", ChatMessageType.Information, "Updating Foreman mod to version " .. serverModVersion .. "...")
            sendModFilesToClientCallback(player)
            player:setValue("foreman_mod_version", serverModVersion)
        end
    end
end
function ModDistributionManager.sendModFilesToClient(player)
    if onServer() then
        local modInfo = {
            version = "2.1.0",
            name = "Foreman Enhanced",
            description = "Enhanced version of the Foreman mod for mining and salvaging automation."
        }
        invokeClientFunction(player, "receiveModFiles", modInfo)
        player:sendChatMessage("Foreman", ChatMessageType.Information, "Mod files sent! Please restart your client to apply updates."%_t)
    end
end
function ModDistributionManager.receiveModFiles(modInfo)
    if onClient() then
        if modInfo then
            print("Foreman: Received mod update - " .. (modInfo.name or "Unknown") .. " v" .. (modInfo.version or "Unknown"))
            local player = Player()
            if player then
                player:sendChatMessage("Foreman", ChatMessageType.Information, "Mod update received! Version " .. (modInfo.version or "Unknown"))
            end
        end
    end
end
return ModDistributionManager
