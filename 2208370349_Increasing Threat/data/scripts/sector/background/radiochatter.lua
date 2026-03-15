--Always add these.
if onClient() then

    local IncreasingThreat_initialize = RadioChatter.initialize
    function RadioChatter.initialize()
        IncreasingThreat_initialize()

        --General
        if self.GeneralShipChatter then
            table.insert(self.GeneralShipChatter, "I've heard pirates will try to kill troublesome captains with something called a 'Decapitation Strike'.")
            table.insert(self.GeneralShipChatter, "... a decapitation strike? That sounds terrifying.")
            table.insert(self.GeneralShipChatter, "No thanks. I don't feel like having some glory-seeking pirates after my head.")
            table.insert(self.GeneralShipChatter, "Is it just me, or have the pirate raids been getting stronger recently?")
            table.insert(self.GeneralShipChatter, "They came from everywhere. The radio practically exploded with their screams for vengeance.")
            table.insert(self.GeneralShipChatter, "There have been rumors about pirates getting smarter when it comes to faking distress calls. No good deed goes unpunished.")
            --Jammer
            table.insert(self.GeneralShipChatter, "I thought the Headhunter Guild kept a tight leash on their blocker tech, but I heard the pirates got their hands on it somehow.")
            --Scorcher
            table.insert(self.GeneralShipChatter, "My cousin survived a pirate raid. She said she still has nightmares about the ship that tore through her shields in seconds.")
            table.insert(self.GeneralShipChatter, "It's not much bigger than a Raider, but I don't think I've ever seen so many anti-shield weapons crammed on a ship before.")
            --Prowler
            table.insert(self.GeneralShipChatter, "It was significantly larger than a Ravager and it looked pretty well-armed. We ran from it first chance we got.")
            table.insert(self.GeneralShipChatter, "A 'Prowler'? But it's the opposite of stealthy...")
            --Pillager
            table.insert(self.GeneralShipChatter, "We've heard whispers of an experimental pirate battleship called the 'Pillager'. I hope it's not as dangerous as those Ravagers!")
            --Devastator
            table.insert(self.GeneralShipChatter, "... it's a massive pirate ship that's absolutely bristling with guns. I pray that I never encounter one.")
            table.insert(self.GeneralShipChatter, "It was a beast of a ship. We had to hammer it with fire for several minutes before it went down.")
        end
    end
end