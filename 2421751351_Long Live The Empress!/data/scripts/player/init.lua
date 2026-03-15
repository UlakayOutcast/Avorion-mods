if onServer() then

    local player = Player()
    
    -- Add the empress framework mission to the player. We don't have access to all the good stuff in the DLC so this will have to continuously run in the background.
    if player.ownsBlackMarketDLC then
        player:addScriptOnce("background/empressframeworkmission.lua")
    end

    --[[
        Special thanks to:
        - SDK
        - Bubbet
        - Hammelpilaw
        - Shrooblord
        - Ren Atlas
        - Hello There
        - Salient
    ]]

end