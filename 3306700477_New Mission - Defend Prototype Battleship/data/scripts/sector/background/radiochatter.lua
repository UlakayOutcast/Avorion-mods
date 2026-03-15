--Always add these.
if onClient() then

    local DefendPrototype_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        DefendPrototype_initialize()

        --General
        if self.GeneralShipChatter then
            --0x726164696F206368617474657220616C77617973205354415254
            --Defend Prototype radio chatter
            table.insert(self.GeneralShipChatter, "The tech used to make those prototypes is tough, but they still can't stand up to Scorchers and Devastators.")
            table.insert(self.GeneralShipChatter, "I've heard that once they're done building it, they basically tear down the whole sector. It's eerie.")
            table.insert(self.GeneralShipChatter, "... she said you should target the Deadshots first. What's a Deadshot?")
            table.insert(self.GeneralShipChatter, "For all the money they spend building those things and hiring mercs, you'd think they'd be better defended.")
            table.insert(self.GeneralShipChatter, "My sister picked up a contract to defend a shipyard last week. She said the attack was ferocious but the pay was great!")
            --0x726164696F206368617474657220616C7761797320454E44

            if random():test(0.25) then
                --0x726164696F2063686174746572203235706374205354415254
                --Defend Prototype radio chatter
                table.insert(self.GeneralShipChatter, "Legit question for any captain. How would you deal with 30-50 angry pirates attacking a shipyard within 3-5 minutes?")
                --0x726164696F206368617474657220323570637420454E44
            end
        end
    end
end