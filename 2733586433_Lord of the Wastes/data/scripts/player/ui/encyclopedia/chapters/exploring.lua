--0x656E6379636C6F7065646961206368205354415254
local _SwenksArticle = {
    title = "Свенкс",
    picture = "data/textures/ui/encyclopedia/exploring/characters/swenks.jpg",
    text = "\\c(0d0)Свенкс\\c() — самозваный Повелитель Железных Пустошей. Несмотря на низкотехнологичный корабль, у него может быть \\c(0d0)пара сюрпризов\\c() в запасе.",

    isUnlocked = function()
        if Player():getValue("encyclopedia_swenks_met") then return true end

        local swenks = Sector():getEntitiesByScript("swenks.lua")
        if swenks then
            -- RemoteInvocations_Ignore
            invokeServerFunction("setValue", "swenks_met")
            return true
        end

        return false
    end
}
--0x656E6379636C6F706564696120636820454E44

--0x656E6379636C6F70656469612063682074626C20696E73
table.insert(category.chapters[10].articles, _SwenksArticle)
