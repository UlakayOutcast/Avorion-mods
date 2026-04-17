--Всегда добавляйте это.
if onClient() then

    local Annihilatorium_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        Annihilatorium_initialize()

        --Общее
        if self.GeneralShipChatter then
            --0x726164696F206368617474657220616C77617973205354415254
            --Радиопереговоры "Аннигиляториума"
            table.insert(self.GeneralShipChatter, "... 'Аннигиляториум'? Это типа... место, куда отправляют вещи для уничтожения?")
            table.insert(self.GeneralShipChatter, "Мой приятель пробовал испытание 'Мастер Арены'. Бедняга потерял свой корабль на первой волне.")
            table.insert(self.GeneralShipChatter, "Моя кузина пыталась сражаться в Аннигиляториуме. Она дошла до 30-й волны, прежде чем ее корабль взорвал Разрушитель-Налетчик.")
            table.insert(self.GeneralShipChatter, "Там надо сражаться пятьдесят волн? Ничего себе! Звучит как огромный гринд.")
            table.insert(self.GeneralShipChatter, "... Я слышал, их больше тридцати разных видов. Сам факт, что их так много, ужасает.")
            --0x726164696F206368617474657220616C7761797320454E44

            if random():test(0.25) then
                --0x726164696F2063686174746572203235706374205354415254
                --Радиопереговоры "Аннигиляториума"
                table.insert(self.GeneralShipChatter, "Я думал, больше никогда не увижу Палача после 'Повышения Угрозы'. Как их набралось столько для того, что по сути является цирком?")
                --0x726164696F206368617474657220323570637420454E44
            end
        end
    end
end