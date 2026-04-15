--Always add these.
if onClient() then

    local IncreasingThreat_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        IncreasingThreat_initialize()

        --General
        if self.GeneralShipChatter then
			table.insert(self.GeneralShipChatter, "Я слышал, что пираты пытаются убить надоедливых капитанов с помощью так называемого 'Сокрушающего удара'.")
            table.insert(self.GeneralShipChatter, "...обезглавливание? Звучит устрашающе.")
            table.insert(self.GeneralShipChatter, "Нет, спасибо. Мне не хочется, чтобы за моей головой охотились пираты, ищущие славы.")
            table.insert(self.GeneralShipChatter, "Мне кажется, или пиратские набеги в последнее время стали сильнее?")
            table.insert(self.GeneralShipChatter, "Они приходили отовсюду. Радио практически взорвалось их криками о мести.")
            table.insert(self.GeneralShipChatter, "Ходят слухи о том, что пираты становятся умнее, когда дело доходит до фальсификации сигналов бедствия. Ни одно доброе дело не остается безнаказанным.")
            --Jammer
            table.insert(self.GeneralShipChatter, "Я думал, что Гильдия охотников за головами держит свою технологию блокировки на жестком поводке, но я слышал, что пираты каким-то образом заполучили ее.")
            --Scorcher
            table.insert(self.GeneralShipChatter, "Моя двоюродная сестра пережила пиратский набег. Она сказала, что ей до сих пор снятся кошмары о корабле, который за секунды прорвал ее щиты.")
            table.insert(self.GeneralShipChatter, "Он ненамного больше 'Рейдера', но я не думаю, что когда-либо раньше видел на корабле столько противощитового оружия.")
            --Prowler
            table.insert(self.GeneralShipChatter, "Он был значительно крупнее 'Опустошителя' и выглядел довольно хорошо вооруженным. Мы убежали от него при первой же возможности.")
            table.insert(self.GeneralShipChatter, "'Бродяга'? Но это противоположность скрытности...")
            --Pillager
            table.insert(self.GeneralShipChatter, "До нас дошли слухи об экспериментальном пиратском линкоре под названием 'Разбойник'. Надеюсь, он не так опасен, как эти 'Опустошители!'")
            --Devastator
            table.insert(self.GeneralShipChatter, "... это огромный пиратский корабль, изобилующий оружием. Я молюсь, чтобы мне никогда с ним не встретиться.")
            table.insert(self.GeneralShipChatter, "Это был чудовищный корабль. Нам пришлось несколько минут бить его огнем, прежде чем он затонул.")
        end
    end
end