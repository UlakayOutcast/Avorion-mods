--Always add these.
if onClient() then

    local DefendPrototype_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        DefendPrototype_initialize()

        --General
        if self.GeneralShipChatter then
            --0x726164696F206368617474657220616C77617973205354415254
            --Defend Prototype radio chatter
            table.insert(self.GeneralShipChatter, "Технология, использованная для создания этих прототипов, сложна, но они все равно не могут противостоять Обжигателям и Опустошителям.")
            table.insert(self.GeneralShipChatter, "Я слышал, что как только они его построят, они практически снесут весь сектор. Это жутко.")
            table.insert(self.GeneralShipChatter, "... она сказала, что сначала тебе следует нацелиться на Deadshot. Что такое Deadshot?")
            table.insert(self.GeneralShipChatter, "Несмотря на все деньги, которые они тратят на строительство этих вещей и найм наемников, можно подумать, что они будут лучше защищены.")
            table.insert(self.GeneralShipChatter, "Моя сестра получила контракт на защиту верфи на прошлой неделе. Она сказала, что нападение было жестоким, но плата была огромной!")
            --0x726164696F206368617474657220616C7761797320454E44

            if random():test(0.25) then
                --0x726164696F2063686174746572203235706374205354415254
                --Defend Prototype radio chatter
                table.insert(self.GeneralShipChatter, "Законный вопрос для любого капитана. Как бы вы справились с 30-50 разгневанными пиратами, напавшими на верфь в течение 3-5 минут?")
                --0x726164696F206368617474657220323570637420454E44
            end
        end
    end
end