--Всегда добавляйте это.
if onClient() then

    local DisruptPirateMiners_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        DisruptPirateMiners_initialize()

        --General
        if self.GeneralShipChatter then
            --0x726164696F206368617474657220616C77617973205354415254
            --Disrupt Pirate Miners radio chatter
            table.insert(self.GeneralShipChatter, "Я слышал о пиратах, управляющих нелицензированными горнодобывающими операциями в последнее время.")
            table.insert(self.GeneralShipChatter, "Моя сестра командовала кораблем, который накрыл нелегальную горнодобывающую операцию. Она сказала, что их трюмы ломились от руды.")
            table.insert(self.GeneralShipChatter, "Даже если вы берете руду у пирата, она все равно считается украденной. Никакого доброго дела, да?")
            --0x726164696F206368617474657220616C7761797320454E44

            if random():test(0.05) then
                --0x726164696F2063686174746572203035706374205354415254
                --Disrupt Pirate Miners radio chatter
                table.insert(self.GeneralShipChatter, "Пытаюсь задеть за живое, и это, вероятно, шахтеррррр")
                --0x726164696F206368617474657220303570637420454E44
            end
        end
    end
end
