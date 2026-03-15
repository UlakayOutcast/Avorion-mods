--Только добавлять это, если игрок достаточно далеко от центра
if onClient() then

    local koth_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        koth_initialize()

        local x, y = Sector():getCoordinates()
        local dist = length(vec2(x, y))

        --0x726164696F2063686174746572206469737420646566696E6974696F6E
        local koth_minDist = Balancing_GetBlockRingMax()
        --0x726164696F2063686174746572206469737420646566696E6974696F6E
        local koth_maxDist = koth_minDist + 25

        --0x726164696F20636861747465722063616D706169676E205354415254
        --Радиоболтовня KOTH
        if self.GeneralShipChatter and dist > koth_minDist and dist < koth_maxDist then
            table.insert(self.GeneralShipChatter, "Вы когда-нибудь задумывались, почему пираты не используют эти восстанавливающие щиты? Что с ними не так?") --hansel / gretel
            table.insert(self.GeneralShipChatter, "Я слышал, как какой-то наемник расспрашивал о Quantum Xsotan на днях. Он, казалось, был очень заинтересован в системе прыжков на короткие расстояния.") --xsologize
            table.insert(self.GeneralShipChatter, "Пираты здесь в последнее время используют более сложные тактики. ... Как думаете, они получают помощь извне?")
            table.insert(self.GeneralShipChatter, "Компания Frostbite? Это грубая банда, но я слышал, что им обычно можно доверять в том, что они поступают правильно.")
            table.insert(self.GeneralShipChatter, "... почему компания, которая продает спутники, убивает любого, кто задает вопросы об их сфере деятельности? Ты звучишь безумно.")

            if random():test(0.25) then
                table.insert(self.GeneralShipChatter, "Бывший сосед моего двоюродного брата слышал слух о спасенных частях Xsotan, появляющихся на сомнительных корпоративных грузовых судах. Это жутко, если вы спросите меня.")
            end

            if random():test(0.05) then
                --Намек на то, что имя Varlance является отсылкой к Хансу Максвеллу Калдеру из FS2: Blue Planet.
                table.insert(self.GeneralShipChatter, "Я слышал, что он потомок какого-то адмирала с Юпитера. ... Что такое 'Юпитер'?")
                --Имя Софи является отсылкой к Кайлу Нетребе (Также из FS2: Blue Planet)
                table.insert(self.GeneralShipChatter, "Нетреба? Кажется, я слышал это имя раньше. Разве он не был древним воином с Марса?")
            end
        end
        --0x726164696F20636861747465722063616D706169676E20454E44
    end
end
