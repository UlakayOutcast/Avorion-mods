-- Добавлять только если игрок достаточно далеко от центра
if onClient() then

    local lotw_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        lotw_initialize()

        local x, y = Sector():getCoordinates()
        local dist = length(vec2(x, y))

        -- Определение максимальной дистанции для радиообмена LOTW
        local lotw_maxdist = 430

        -- Радиообмен LOTW
        if self.GeneralShipChatter and dist > lotw_maxdist then
            table.insert(self.GeneralShipChatter, "Я не думал, что пираты здесь так хорошо организованы, но, похоже, я ошибся.")
            table.insert(self.GeneralShipChatter, "... что ты имеешь в виду под 'ещё один пиратский босс'? Я не думал, что Свокс имеет какое-то влияние так далеко.")
            table.insert(self.GeneralShipChatter, "Я слышал слухи о хорошо организованной пиратской операции. Но так далеко на окраине? Безумно.")
            table.insert(self.GeneralShipChatter, "... он действительно называет это 'железными пустошами'? Мы тоже цивилизованные, знаешь ли!")
            table.insert(self.GeneralShipChatter, "Наш собственный пиратский босс! А я думал, что в этой местности слишком пустынно для чего-то интересного.")

            if random():test(0.25) then
                table.insert(self.GeneralShipChatter, "Я слышал, как один пират хвастался, что установил на своём корабле систему Мститель и Железный занавес. Потребление энергии должно быть сумасшедшим — надеюсь, у него хороший реактор.")
            end

            if random():test(0.05) then
                table.insert(self.GeneralShipChatter, "Говорят, он очень злится, если его сравнивают со Своксом.")
            end
        end
    end
end
