local LOTW_RefreshIcon = BulletinBoard.refreshIcon
function BulletinBoard.refreshIcon()
    local _MethodName = "Refresh Icon"

    LOTW_RefreshIcon()
    --0x6D697373696F6E2062756C6C6574696E20747261636B657220626F6F6C
    local containsLOTWBulletin = false
    local displayed = BulletinBoard.getDisplayedBulletins()

    --0x6D697373696F6E2062756C6C6574696E20747261636B6572207061747465726E205354415254
    local lotw_patterns = {
        "lotwstory1.lua",
        "lotwside1.lua",
        "lotwside2.lua"
    }
    --0x6D697373696F6E2062756C6C6574696E20747261636B6572207061747465726E20454E44

    for _, bulletin in pairs(displayed) do
        --0x6D697373696F6E2062756C6C6574696E207061747465726E20666F7265616368205354415254
        for _, pattern in pairs(lotw_patterns) do
            if string.find(bulletin.script, pattern) then
                containsLOTWBulletin = true
                break
            end
        end
        --0x6D697373696F6E2062756C6C6574696E207061747465726E20666F726561636820454E44

        if containsLOTWBulletin then
            break
        end
    end

    local entityIcon = EntityIcon()

    --0x6D697373696F6E2062756C6C6574696E20636F6C6F72205354415254
    if containsLOTWBulletin then
        BulletinBoard.Log(_MethodName, "Station has LOTW mission - setting icon / color")
        entityIcon.secondaryIcon = "data/textures/icons/pixel/mission-white.png"
        entityIcon.secondaryIconColor = ColorRGB(0.9686, 0.9686, 0.2862)
    end
    --0x6D697373696F6E2062756C6C6574696E20636F6C6F7220454E44
end