-- Alright, so here's the deal. The strategy map has a comprehensive list of all of the crew available for hire in each of the stations, but the way it does this completely gates out modded captains and will crash if any are hireable. What I'm going to do to get around this is check if this arbitrary that we need to mod exists globally, then just add to it. If it doesn't then we need to overwrite the vanilla function with effectively the exact same function MINUS the arbitrary table we need to edit. This should allow anyone to copy and paste this entire file without breaking each other.



if not _G["simplifiedIcons"] then

	_G["simplifiedIcons"]={}
	-- Vanilla captains:
	simplifiedIcons[CaptainUtility.ClassType.Commodore] = {path = "data/textures/icons/captain-commodore.png", color = ColorRGB(0, 0.74, 0.74)}
    simplifiedIcons[CaptainUtility.ClassType.Smuggler] = {path = "data/textures/icons/captain-smuggler.png", color = ColorRGB(0.78, 0.03, 0.75)}
    simplifiedIcons[CaptainUtility.ClassType.Merchant] = {path = "data/textures/icons/captain-merchant.png", color = ColorRGB(0.5, 0.8, 0)}
    simplifiedIcons[CaptainUtility.ClassType.Miner] = {path = "data/textures/icons/captain-miner.png", color = ColorRGB(0.5, 0.8, 0)}
    simplifiedIcons[CaptainUtility.ClassType.Scavenger] = {path = "data/textures/icons/captain-scavenger.png", color = ColorRGB(0.1, 0.5, 1)}
    simplifiedIcons[CaptainUtility.ClassType.Explorer] = {path = "data/textures/icons/captain-explorer.png", color = ColorRGB(1, 0.88, 0.04)}
    simplifiedIcons[CaptainUtility.ClassType.Daredevil] = {path = "data/textures/icons/captain-daredevil.png", color = ColorRGB(0.9, 0.1, 0.1)}
    simplifiedIcons[CaptainUtility.ClassType.Scientist] = {path = "data/textures/icons/captain-scientist.png", color = ColorRGB(1, 0.47, 0)}
    simplifiedIcons[CaptainUtility.ClassType.Hunter] = {path = "data/textures/icons/captain-hunter.png", color = ColorRGB(1, 0.43, 0.77)}
	
	--overwrite the original function with a slightly modified one
	function SectorShipOverview.refreshCrewList()
		local lists = self.collectEntities()
		local stationList = lists[1]
		local player = Player()

		self.crewList:clear()

		local white = ColorRGB(1, 1, 1)

		local renderer = UIRenderer()

		local classProperties = CaptainUtility.ClassProperties()

		for _, entry in pairs(stationList.entries) do

			local entity = entry.entity
			local color = renderer:getEntityTargeterColor(entity)

			if not entity:hasScript("data/scripts/entity/crewboard.lua") then return end

			self.stationsOfferingCrew = self.stationsOfferingCrew + 1

			local ok, crew, captain = entity:invokeFunction("data/scripts/entity/crewboard.lua", "getAvailableCrewAndCaptain")

			if not crew and not captain then return end

			local captainIcons = {}
			local captainTooltip = ""

			if captain then
				if captain.primaryClass == 0 then
					table.insert(captainIcons, {path = "data/textures/icons/captain-noclass.png", color = ColorRGB(1, 1, 1)})
					captainTooltip = "Captain [no class"%_t
				else
					table.insert(captainIcons, simplifiedIcons[captain.primaryClass])
					captainTooltip = "Captain ["%_t .. classProperties[captain.primaryClass].displayName % _t
				end

				if captain.secondaryClass and captain.secondaryClass ~= 0 then
					table.insert(captainIcons, simplifiedIcons[captain.secondaryClass])
					captainTooltip = captainTooltip .. ", " .. classProperties[captain.secondaryClass].displayName % _t
				end

				captainTooltip = captainTooltip .. "]"
			end

			local icons = {}
			local tooltips = {}

			for _, crewMember in pairs(crew) do
				local professionNumber = crewMember.profession
				local profession = CrewProfession(professionNumber)
				table.insert(icons, profession.icon)
				table.insert(tooltips, profession:name(profession) % _t)
			end

			if captain or #icons > 0 then
				self.crewList:addRow(entity.id.string)
				self.crewList:setEntry(0, self.crewList.rows - 1, entry.icon, false, false, white, self.crewList.width - 2 * self.iconColumnWidth)
				self.crewList:setEntryType(0, self.crewList.rows - 1, ListBoxEntryType.PixelIcon)

				self.crewList:setEntry(1, self.crewList.rows - 1, entry.name, false, false, color, self.crewList.width - 2 * self.iconColumnWidth)
				self.crewList:setEntryType(1, self.crewList.rows - 1, ListBoxEntryType.Text)

				self.crewList:setEntry(11, self.crewList.rows - 1, entry.group, false, false, white, self.crewList.width - 2 * self.iconColumnWidth)

				self.crewRowsAdded = self.crewRowsAdded + 1
				self.crewList:addRow(entity.id.string)
				for i = 1, #icons do
					if i == 1 then
						if captain then
							self.crewList:setEntry(i, self.crewList.rows - 1, captainIcons[i].path, false, false, captainIcons[i].color, 0)
						else
							self.crewList:setEntry(i, self.crewList.rows - 1, "data/textures/icons/nothing.png", false, false, white, 0)
						end

						self.crewList:setEntryType(i, self.crewList.rows - 1, ListBoxEntryType.Icon)
						self.crewList:setEntryTooltip(i, self.crewList.rows - 1, captainTooltip)
					else
						self.crewList:setEntry(i, self.crewList.rows - 1, icons[i], false, false, white, 0)
						self.crewList:setEntryType(i, self.crewList.rows - 1, ListBoxEntryType.Icon)
						self.crewList:setEntryTooltip(i, self.crewList.rows - 1, tooltips[i])
					end
				end
			end
		end

		if player.selectedObject then
			self.crewList:selectValueNoCallback(player.selectedObject.string)
		end

		self.crewList.scrollPosition = scrollPosition
	end

end



-- Modded captains
simplifiedIcons[CaptainUtility.ClassType.SquadLeader] = {path = "data/textures/icons/captain.png", color = ColorRGB(0.85, 0.6, 0.1)}
simplifiedIcons[CaptainUtility.ClassType.ShieldMaster] = {path = "data/textures/icons/captain.png", color = ColorRGB(0.4, 0.4, 1.0)}
simplifiedIcons[CaptainUtility.ClassType.AICaptain] = {path = "data/textures/icons/captain.png", color = ColorRGB(0.0, 0.5, 1.0)}
simplifiedIcons[CaptainUtility.ClassType.LimitBreaker] = {path = "data/textures/icons/captain.png", color = ColorRGB(0.8, 0.3, 0.3)}
simplifiedIcons[CaptainUtility.ClassType.StarSurfer] = {path = "data/textures/icons/captain.png", color = ColorRGB(0.7, 0.3, 0.7)}
simplifiedIcons[CaptainUtility.ClassType.LootGoblin] = {path = "data/textures/icons/captain.png", color = ColorRGB(0.1, 0.8, 0.1)}