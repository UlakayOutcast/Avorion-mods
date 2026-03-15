-- Concept: add a new "Wreckages" tab to the strategy mode tabs.
-- Display a list of all wreckages in the sector, sorted by how big they are.
-- Cool to add: benefits for Scavenger captains and particular subsystem upgrades
-- (scanners?) to see more information, e.g. resource richness.
if onClient() then

local swt_initialize_original = SectorShipOverview.initialize
function SectorShipOverview.initialize()
    swt_initialize_original()
    SectorShipOverview.buildWreckagesUI()
    SectorShipOverview.refreshWreckagesList()
end

local swt_show_original = SectorShipOverview.show
function SectorShipOverview.show()
    swt_show_original()
    self.refreshWreckagesList()
end

-- The wreckages refresh is somewhat expensive so we won't do it each and every
-- second like some of the updates.
local swt_update_counter = 0
local swt_update_frequency = 3

local swt_updateClient_original = SectorShipOverview.updateClient
function SectorShipOverview.updateClient(timestep)
    local lastTab = self.lastActiveTab
    swt_updateClient_original(timestep)
    local activeTab = self.lastActiveTab

    -- We get called a little out of order and need some additional checking
    if not self.wreckagesTab then return end

    if activeTab == self.wreckagesTab.index
        and (lastTab ~= activeTab or swt_update_counter % swt_update_frequency == 0)
    then
        SectorShipOverview.refreshWreckagesList()
    end

    swt_update_counter = swt_update_counter + 1
end

local swt_show_original = SectorShipOverview.show
function SectorShipOverview.show()
    swt_show_original()
    SectorShipOverview.refreshWreckagesList()
end

function SectorShipOverview.buildWreckagesUI()
    self.wreckagesTab = self.tabbedWindow:createTab("Wreckages"%_t, "data/textures/icons/wreckage.png", "Wreckages"%_t)
    local hsplit = UIHorizontalSplitter(Rect(self.wreckagesTab.size), 0, 0, 0.0)
    self.wreckagesList = self.wreckagesTab:createListBoxEx(hsplit.bottom)
    self.wreckagesList.columns = 3
    self.wreckagesList.rowHeight = self.rowHeight
    self.wreckagesList:setColumnWidth(0, self.iconColumnWidth)
    local notColumnWidth = self.wreckagesList.width - self.iconColumnWidth
    self.wreckagesList:setColumnWidth(1, notColumnWidth * 2 / 3)
    self.wreckagesList:setColumnWidth(2, notColumnWidth / 3)
    self.wreckagesList.onSelectFunction = "onEntrySelected"
end

local wreckageNames = {
    huge = {
        "Husk"%_t, 
        "Derelict"%_t,
        "Ruin"%_t,
        "Hulk"%_t,
    },
    large = {
        "Skeleton"%_t,
        "Wreckage"%_t,
        "Remnant"%_t
    },
    medium = {
        "Flotsam"%_t,
        "Wreck"%_t
    },
    small = {
        "Salvage"%_t,
        "Dross"%_t
    },
    tiny = {
        "Fragments"%_t,
        "Debris"%_t,
        "Scraps"%_t,
        "Detritus"%_t
    }
}


local function getWreckageDetectorHighlightRange(ship)
    local highlightRange = 0
	if ship then 
		local captain = ship:getCaptain()

		-- Проверяем наличие капитана-шахтёра
		if captain and captain:hasClass(CaptainUtility.ClassType.Scavenger) then
			highlightRange = 400 + captain.tier *300 + captain.level * 175
		else
			-- Проверяем наличие подсистемы
			local system = ShipSystem(ship)
			if system then
				for upgrade, _ in pairs(system:getUpgrades()) do
					if string.find(upgrade.script, "WS") then
						-- Получаем радиус из системы напрямую
						local ret, range = ship:invokeFunction(upgrade.script, "getBonuses", upgrade.seed, upgrade.rarity)
						if ret == 0 and range then
							highlightRange = range
						end
					end
				end
			end
		end
    end

    return highlightRange
end

function SectorShipOverview.refreshWreckagesList()
    if not self.wreckagesList then return end

    local startingScrollPosition = self.wreckagesList.scrollPosition

    local sector = Sector()
    local player = Player()
    local ship = player.craft
    local wreckages = {sector:getEntitiesByType(EntityType.Wreckage)}
    table.sort(wreckages, function (w1, w2) return w1.mass > w2.mass end)

    self.wreckagesList:clear()

    if not ship then
        return
    end

    local white = ColorRGB(1, 1, 1)
    local gray = ColorRGB(0.6, 0.6, 0.6)
	
    local highlightRange = getWreckageDetectorHighlightRange(ship)
    if highlightRange == 0 then
        self.wreckagesList:addRow("no_system")
        local wreckagesIcon = "data/textures/icons/scrap-metal.png"
        self.wreckagesList:setEntry(0, self.wreckagesList.rows - 1, wreckagesIcon, false, false, gray)
        self.wreckagesList:setEntry(1, self.wreckagesList.rows - 1, "Субсистема не установлена!", false, false, ColorRGB(1, 0.5, 0.5))
        self.wreckagesList:setEntry(2, self.wreckagesList.rows - 1, "", false, false, gray)
        self.wreckagesList:setEntryType(0, self.wreckagesList.rows - 1, ListBoxEntryType.Icon)
        return
    end

    local getMassString = function(entity)
        if not entity then return "" end
        local seed = Seed(entity.id.string)
        local name = function(list) return randomEntry(Random(seed), list) end
        if entity.mass >= 100 * 1000 * 1000 then
            return round(entity.mass / 1000 / 1000, 0) .. " Mt -- " .. name(wreckageNames.huge)
        elseif entity.mass >= 1000 * 1000 then
            return round(entity.mass / 1000 / 1000, 1) .. " Mt -- " .. name(wreckageNames.huge)
        elseif entity.mass >= 100 * 1000 then
            return round(entity.mass / 1000, 0) .. " Kt -- " .. name(wreckageNames.large)
        elseif entity.mass >= 1000 then
            return round(entity.mass / 1000, 1) .. " Kt -- " .. name(wreckageNames.medium)
        elseif entity.mass >= 100 then
            return round(entity.mass, 0) .. " t -- " .. name(wreckageNames.small)
        else
            return round(entity.mass, 1) .. " t -- " .. name(wreckageNames.tiny)
        end
    end

    local getDistString = function(entity)
        if not ship or not entity then return "" end
        local dist = ship:getNearestDistance(entity)
        if dist >= 100 then return round(dist / 100, 1) .. "km" end
        return round(dist / 100, 2) .. "km"
    end

    local scrapIcon = "data/textures/icons/wreckage.png"

    for _, wreckage in pairs(wreckages) do
        local dist = ship:getNearestDistance(wreckage)
        if dist <= highlightRange then  -- Проверяем, что обломок в радиусе
            self.wreckagesList:addRow(wreckage.id.string)
            self.wreckagesList:setEntry(0, self.wreckagesList.rows - 1, scrapIcon, false, false, gray)
            self.wreckagesList:setEntry(1, self.wreckagesList.rows - 1, getMassString(wreckage), false, false, white)
            self.wreckagesList:setEntry(2, self.wreckagesList.rows - 1, getDistString(wreckage), false, false, gray)
            self.wreckagesList:setEntryType(0, self.wreckagesList.rows - 1, ListBoxEntryType.Icon)
        end
    end

    if player.selectedObject then
        self.wreckagesList:selectValueNoCallback(player.selectedObject.string)
    end

    self.wreckagesList.scrollPosition = startingScrollPosition
end


end -- if onClient()