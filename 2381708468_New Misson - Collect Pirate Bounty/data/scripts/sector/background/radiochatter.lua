--Всегда добавляйте это.
if onClient() then

    local CollectPirateBounty_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        CollectPirateBounty_initialize()

        --General
        if self.GeneralShipChatter then
            --0x726164696F206368617474657220616C77617973205354415254
            --Collect Pirate Bounty radio chatter
            table.insert(self.GeneralShipChatter, "Я слышал, некоторые пираты назначают награду за головы капитанов, которые на них охотятся.")
            table.insert(self.GeneralShipChatter, "... Я слышал, как один капитан жаловался на постоянные атаки охотников за головами. Думаю, он не знал, что они прекратятся, если он откажется от контракта.")
            table.insert(self.GeneralShipChatter, "Получать деньги за убийство пиратов? Если я все равно собирался это делать, то это практически бесплатные деньги, верно?")
            --0x726164696F206368617474657220616C7761797320454E44
        end
    end
end
