--Всегда добавляйте это.
if onClient() then

    local Annihilatorium_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        Annihilatorium_initialize()

        --General
        if self.GeneralShipChatter then
            --0x726164696F206368617474657220616C77617973205354415254
            --Annihilatorium radio chatter
            table.insert(self.GeneralShipChatter, "... 'Аннигилятор'? Это типа... куда отправляют вещи, чтобы их уничтожили?")
            table.insert(self.GeneralShipChatter, "Мой приятель попробовал пройти испытание 'Мастер арены'. Бедняга потерял свой корабль на первой же волне.")
            table.insert(self.GeneralShipChatter, "Моя кузина пыталась сражаться в Аннигиляторе. Она дошла до 30-й волны, прежде чем ее корабль взорвал Джаггернаут-мародер.")
            table.insert(self.GeneralShipChatter, "Они заставляют тебя сражаться пятьдесят волн? Вау! Звучит как огромный гринд.")
            table.insert(self.GeneralShipChatter, "... Я слышал, их больше тридцати разных видов. Тот факт, что их так много, ужасает.")
            --0x726164696F206368617474657220616C7761797320454E44

            if random():test(0.25) then
                --0x726164696F2063686174746572203235706374205354415254
                --Annihilatorium radio chatter
                table.insert(self.GeneralShipChatter, "Я думал, что больше никогда не увижу Палача после 'Нарастающей угрозы'. Как они заполучили так много для, по сути, цирка?")
                --0x726164696F206368617474657220323570637420454E44
            end
        end
    end
end
