function TradingManager:useUpBoughtGoods(timeStep)

    if not self.useUpGoodsEnabled then return end

    local tickTime = 120 ------------ CHANGE HERE for Timer   120=2 Minutes is Default

    self.useTimeCounter = self.useTimeCounter + timeStep
    if self.useTimeCounter > tickTime then
        self.useTimeCounter = self.useTimeCounter - tickTime
        local faction = Faction()
        if faction then
            local station = Entity()
            local x, y = Sector():getCoordinates()
            for i = 1, #self.boughtGoods do
                local dice=math.random()*math.random()
                if dice<0.36 then goto continue end
                
                local amount = math.random(20, 50)/100 --------- CHANGE HERE  minimum, maximum Default is 30-80
                local good = self.boughtGoods[i]

                if not good then goto continue end

                local inStock = self:getNumGoods(good.name)
                amount = math.ceil(amount*inStock)

                if amount == 0 then goto continue end
                self:decreaseGoods(good.name, amount)

                local percent = math.random(107, 123) / 100
                local price = self:getBuyPrice(good.name)
                local received = price * percent * amount ------------ CHANGE HERE for % income  Default is 10%
                local description = Format("\\s(%1%:%2%) %3% consumed %4% %5% and paid you ¢%6% (¢%7% profit)."%_T,
                                                x, y,
                                                station.name,
                                                math.floor(amount),
                                                good:pluralForm(math.floor(amount)),
                                                createMonetaryString(received),
                                                createMonetaryString(price * amount * (percent - 1)))  ------------ CHANGE HERE for % income  Default is 10%

                faction:receive(description, received)
                self.stats.moneyGainedFromGoods = self.stats.moneyGainedFromGoods + received
                ::continue::
            end
        end
    end
end