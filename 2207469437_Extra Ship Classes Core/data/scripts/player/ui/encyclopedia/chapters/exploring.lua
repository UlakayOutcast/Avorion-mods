--1 = Katana
local _KatanaArticle = {
    title = "Baleful Katana",
    picture = "data/textures/ui/encyclopedia/exploring/characters/pirate1.jpg",
    text = "A straightforward, brutal combatant that balances offensive and defensive capabilities on a knife's edge. The \\c(0d0)Baleful Katana\\c() can \\c(0d0)adapt its shields\\c() to its opponent's primary weapons, and it can also power up its \\c(0d0)overdrive system\\c() to pulverize its target into space dust.",
    isUnlocked = function()
        if Player():getValue("encyclopedia_escc_katana_met") then
            return true
        end

        local _Katana = Sector():getEntitiesByScriptValue("_escc_is_baleful_katana")
        if _Katana then
            invokeServerFunction("setValue", "escc_katana_met")
            return true
        end

        return false
    end
}

--2 = Goliath
local _GoliathArticle = {
    title = "Dervish Goliath",
    picture = "data/textures/ui/encyclopedia/exploring/characters/pirate1.jpg",
    text = "As if the seeking missile and \\c(0d0)torpedo batteries\\c() weren't enough, the \\c(0d0)Dervish Goliath\\c() is also equipped with a \\c(0d0)phasing system\\c(). It is also capable of taking an enormous amount of punishment before going down.",
    isUnlocked = function()
        if Player():getValue("encyclopedia_escc_goliath_met") then
            return true
        end

        local _Goliath = Sector():getEntitiesByScriptValue("_escc_is_dervish_goliath")
        if _Goliath then
            invokeServerFunction("setValue", "escc_goliath_met")
            return true
        end

        return false
    end
}

--3 = Hellcat
local _HellcatArticle = {
    title = "Relentless Hellcat",
    picture = "data/textures/ui/encyclopedia/exploring/characters/pirate1.jpg",
    text = "Perhaps the epitome of offense and defense merged into one terrifying package, the \\c(0d0)Relentless Hellcat\\c() closes with enemies under the cover of its powerful \\c(0d0)phasing system\\c() and tears them apart with its short-range lasers. Retreating will just give it a chance to \\c(0d0)regenerate\\c() its hull.",
    isUnlocked = function()
        if Player():getValue("encyclopedia_escc_hellcat_met") then
            return true
        end

        local _Hellcat = Sector():getEntitiesByScriptValue("_escc_is_relentless_hellcat")
        if _Hellcat then
            invokeServerFunction("setValue", "escc_hellcat_met")
            return true
        end

        return false
    end
}

--4 = Hunter
local _HunterArticle = {
    title = "Steadfast Hunter",
    picture = "data/textures/ui/encyclopedia/exploring/characters/pirate1.jpg",
    text = "The \\c(0d0)Steadfast Hunter\\c() prefers to fight at long range and snipe at its opponents with a \\c(0d0)powerful laser weapon\\c(). Its impeccable \\c(0d0)point defense systems\\c() mean that torpedoes and won't work as countermeasures when it retreats.",
    isUnlocked = function()
        if Player():getValue("encyclopedia_escc_hunter_met") then
            return true
        end

        local _Hunter = Sector():getEntitiesByScriptValue("_escc_is_steadfast_hunter")
        if _Hunter then
            invokeServerFunction("setValue", "escc_hunter_met")
            return true
        end

        return false
    end
}

--5 = Shield
local _ShieldArticle = {
    title = "Vigilant Shield",
    picture = "data/textures/ui/encyclopedia/exploring/characters/pirate1.jpg",
    text = "The \\c(0d0)Vigilant shield\\c() is capable of \\c(0d0)enhancing its allies\\c() with a number of powerful offensive and defensive abilities as the engagement continues. It is also capable of \\c(0d0)adapting its defenses\\c() to the enemy's offensive capabilities. Beware its \\c(0d0)point defenses\\c() and \\c(0d0)powerful reinforcements\\c().",
    isUnlocked = function()
        if Player():getValue("encyclopedia_escc_vigshield_met") then
            return true
        end

        local _Shield = Sector():getEntitiesByScriptValue("_escc_is_vigilant_shield")
        if _Shield then
            invokeServerFunction("setValue", "escc_vigshield_met")
            return true
        end

        return false
    end
}

--6 = Phoenix
local _PhoenixArticle = {
    title = "Scouring Phoenix",
    picture = "data/textures/ui/encyclopedia/exploring/characters/pirate1.jpg",
    text = "The \\c(0d0)Scouring Phoenix\\c() lobs \\c(0d0)powerful nuclear torpedoes\\c() at its target. Volleys of shells from its burst fire cannons mop up any survivors, especially when its \\c(0d0)overdrive system\\c() is active.",
    isUnlocked = function()
        if Player():getValue("encyclopedia_escc_phoenix_met") then
            return true
        end

        local _Phoenix = Sector():getEntitiesByScriptValue("_escc_is_scouring_phoenix")
        if _Phoenix then
            invokeServerFunction("setValue", "escc_phoenix_met")
            return true
        end

        return false
    end
}

table.insert(category.chapters[10].articles, _KatanaArticle)
table.insert(category.chapters[10].articles, _GoliathArticle)
table.insert(category.chapters[10].articles, _HellcatArticle)
table.insert(category.chapters[10].articles, _HunterArticle)
table.insert(category.chapters[10].articles, _ShieldArticle)
table.insert(category.chapters[10].articles, _PhoenixArticle)