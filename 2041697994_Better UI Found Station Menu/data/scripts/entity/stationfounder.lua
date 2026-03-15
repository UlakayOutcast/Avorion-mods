-- this function gets called on creation of the entity the script is attached to, on client and server
--function initialize()
--
--end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function StationFounder.initUI()
    local res = getResolution()
    local size = vec2(650, 575)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	

    window.caption = "Transform to Station"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Found Station"%_t);
	
	--filter text box
	local filterTextBox = window:createTextBox(Rect(vec2(150, 20)), "onFilterStationName")
	filterTextBox.position = vec2(window.position.x + window.width - 200, window.position.y + 20)
	filterTextBox.backgroundText = "Filter..."

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create buy tab
    local buyTab0 = tabbedWindow:createTab("Basic"%_t, "data/textures/icons/station.png", "Basic Factories"%_t)
    local buyTab1 = tabbedWindow:createTab("Low"%_t, "data/textures/icons/station.png", "Low Tech Factories"%_t)
    local buyTab2 = tabbedWindow:createTab("Advanced"%_t, "data/textures/icons/station.png", "Advanced Factories"%_t)
    local buyTab3 = tabbedWindow:createTab("High"%_t, "data/textures/icons/station.png", "High Tech Factories"%_t)
    local buyTab4 = tabbedWindow:createTab("Other Stations"%_t, "data/textures/icons/stars-stack.png", "Other Stations"%_t)

    StationFounder.buildMiscStationGui(buyTab4)
    StationFounder.buildFactoryGui({0}, buyTab0)
    StationFounder.buildFactoryGui({1, 2, 3}, buyTab1)
    StationFounder.buildFactoryGui({4, 5, 6}, buyTab2)
    StationFounder.buildFactoryGui({7, 8, 9}, buyTab3)
	
	StationFounder.tabbedWindow = tabbedWindow
	StationFounder.buyTab0 = buyTab0
	StationFounder.buyTab1 = buyTab1
	StationFounder.buyTab2 = buyTab2
	StationFounder.buyTab3 = buyTab3
	StationFounder.buyTab4 = buyTab4

    -- warn box
    local size = vec2(550, 290)
    local warnWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    StationFounder.warnWindow = warnWindow
    warnWindow.caption = "Confirm Transformation"%_t
    warnWindow.showCloseButton = 1
    warnWindow.moveable = 1
    warnWindow.visible = false

    local hsplit = UIHorizontalSplitter(Rect(vec2(), warnWindow.size), 10, 10, 0.5)
    hsplit.bottomSize = 40

    warnWindow:createFrame(hsplit.top)

    local ihsplit = UIHorizontalSplitter(hsplit.top, 10, 10, 0.5)
    ihsplit.topSize = 20

    local label = warnWindow:createLabel(ihsplit.top.lower, "Warning"%_t, 16)
    label.size = ihsplit.top.size
    label.bold = true
    label.color = ColorRGB(0.8, 0.8, 0)
    label:setTopAligned();

    local warnWindowLabel = warnWindow:createLabel(ihsplit.bottom.lower, "Text"%_t, 14)
    StationFounder.warnWindowLabel = warnWindowLabel
    warnWindowLabel.size = ihsplit.bottom.size
    warnWindowLabel:setTopAligned();
    warnWindowLabel.wordBreak = true
    warnWindowLabel.fontSize = 14


    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    warnWindow:createButton(vsplit.left, "OK"%_t, "onConfirmTransformationButtonPress")
    warnWindow:createButton(vsplit.right, "Cancel"%_t, "onCancelTransformationButtonPress")

end

function StationFounder.buildMiscStationGui(tab, filter)
	filter = filter or ""
    -- make levels a table with key == value

    -- create background
    local frame = tab:createScrollFrame(Rect(vec2(), tab.size))
    frame.scrollSpeed = 40
    frame.paddingBottom = 17


    local count = 0
	table.sort(StationFounder.stations, function(a, b) return a.name < b.name end)
    for index, station in pairs(StationFounder.stations) do

        local stationName = station.name
		if string.find(string.lower(stationName), string.lower(filter)) then
		
			local padding = 10
			local height = 30
			local width = frame.size.x - padding * 4

			local lower = vec2(padding, padding + ((height + padding) * count))
			local upper = lower + vec2(width, height)

			local rect = Rect(lower, upper)

			local vsplit = UIVerticalSplitter(rect, 10, 0, 0.8)
			vsplit.rightSize = 100

			local button = frame:createButton(vsplit.right, "Transform"%_t, "onFoundStationButtonPress")
			button.textSize = 16
			button.bold = false

			frame:createFrame(vsplit.left)

			vsplit = UIVerticalSplitter(vsplit.left, 10, 7, 0.7)

			local label = frame:createLabel(vsplit.left.lower, stationName, 14)
			label.size = vec2(vsplit.left.size.x, vsplit.left.size.y)
			label:setLeftAligned()

			label.tooltip = station.tooltip or ""

			local costs = StationFounder.getStationCost(station)

			local label = frame:createLabel(vsplit.right.lower, createMonetaryString(costs) .. " Cr"%_t, 14)
			label.size = vec2(vsplit.right.size.x, vsplit.right.size.y)
			label:setRightAligned()

			StationFounder.stationsByButton[button.index] = index

			count = count + 1
			
		end
    end
end

function StationFounder.buildFactoryGui(levels, tab, filter)
	filter = filter or ""

    -- make levels a table with key == value
    local l = {}
    for _, v in pairs(levels) do
        l[v] = v
    end
    levels = l

    -- create background
    local frame = tab:createScrollFrame(Rect(vec2(), tab.size))
    frame.scrollSpeed = 40
    frame.paddingBottom = 17

    local usedProductions = {}
    local possibleProductions = {}

    for good, productions in pairs(productionsByGood) do

        for index, production in ipairs(productions) do
            -- mines shouldn't be built just like that, they need asteroids
            if not production.mine then

                -- read data from production
                local result = goods[production.results[1].name];

                -- only insert if the level is in the list
                if good == production.results[1].name then
                    if levels[result.level] ~= nil and not usedProductions[production.index] then
                        usedProductions[production.index] = true
                        table.insert(possibleProductions, {production=production, index=index})
                    end
                end
            end
        end
    end

    local comp = function(a, b)
        local nameA = getTranslatedFactoryName(a.production)
        local nameB = getTranslatedFactoryName(b.production)
        return nameA < nameB
    end
	
    table.sort(possibleProductions, comp)

    local count = 0
    for _, p in pairs(possibleProductions) do

        local production = p.production
        local index = p.index

        local result = goods[production.results[1].name];
        local factoryName = getTranslatedFactoryName(production)
		
		if string.find(string.lower(factoryName), string.lower(filter)) then

			local padding = 10
			local height = 30
			local width = frame.size.x - padding * 4

			local lower = vec2(padding, padding + ((height + padding) * count))
			local upper = lower + vec2(width, height)

			local rect = Rect(lower, upper)

			local vsplit = UIVerticalSplitter(rect, 10, 0, 0.8)
			vsplit.rightSize = 100

			local button = frame:createButton(vsplit.right, "Transform"%_t, "onFoundFactoryButtonPress")
			button.textSize = 16
			button.bold = false

			frame:createFrame(vsplit.left)

			vsplit = UIVerticalSplitter(vsplit.left, 10, 7, 0.7)

			local label = frame:createLabel(vsplit.left.lower, factoryName, 14)
			label.size = vec2(vsplit.left.size.x, vsplit.left.size.y)
			label:setLeftAligned()

			local tooltip = "Produces:\n"%_t
			for i, result in pairs(production.results) do
				if i > 1 then tooltip = tooltip .. "\n" end
				tooltip = tooltip .. " - " .. result.name%_t
			end


			local first = 1
			for _, i in pairs(production.ingredients) do
				if first == 1 then
					tooltip = tooltip .. "\n\n" .. "Requires:"%_t
					first = 0
				end
				tooltip = tooltip .. "\n - " .. i.name%_t
			end
			label.tooltip = tooltip

			local costs = getFactoryCost(production) * (StationFounder.priceFactor or 1)

			local label = frame:createLabel(vsplit.right.lower, createMonetaryString(costs) .. " Cr"%_t, 14)
			label.size = vec2(vsplit.right.size.x, vsplit.right.size.y)
			label:setRightAligned()


			StationFounder.productionsByButton[button.index] = {goodName = result.name, factory=factoryName, index = index, production = production}

			count = count + 1
			
		end
    end
end

function StationFounder.onConfirmTransformationButtonPress(button)
    if StationFounder.selectedProduction then
        invokeServerFunction("foundFactory", StationFounder.selectedProduction.goodName, StationFounder.selectedProduction.index)
    elseif StationFounder.selectedStation then
        invokeServerFunction("foundStation", StationFounder.stations[StationFounder.selectedStation])
    end
end

function StationFounder.foundStation(template)
    if anynils(template) then return end

    local buyer, ship, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FoundStations)
    if not buyer then return end

    local settings = GameSettings()
    if settings.maximumPlayerStations > 0 and buyer.numStations >= settings.maximumPlayerStations then
        player:sendChatMessage("", 1, "Maximum station limit per faction (%s) of this server reached!"%_t, settings.maximumPlayerStations)
        return
    end
	
    if template == nil then
        player:sendChatMessage("", 1, "The station you chose doesn't exist."%_t)
        return
    end

    -- check if player has enough money
    local cost = StationFounder.getStationCost(template)

    local canPay, msg, args = buyer:canPay(cost)
    if not canPay then
        player:sendChatMessage("Station Founder"%_t, 1, msg, unpack(args))
        return
    end

    local station = StationFounder.transformToStation(buyer)
    if not station then return end

    buyer:pay(Format("Paid %2% Credits to found a %1%."%_T, template.name), cost)

    -- make a factory
    for _, script in pairs(template.scripts) do
        local path = script.script
        local args = script.args or {}

        station:addScript(path, unpack(args))
    end

    -- remove all cargo that might have been added by scripts
    for cargo, amount in pairs(station:getCargos()) do
        station:removeCargo(cargo, amount)
    end

    -- insert cargo of the ship that founded the station
    for good, amount in pairs(ship:getCargos()) do
        station:addCargo(good, amount)
    end
end
callable(StationFounder, "foundStation")

function StationFounder.onFilterStationName(textBox)
	StationFounder.buyTab0:clear()
	StationFounder.buyTab1:clear()
	StationFounder.buyTab2:clear()
	StationFounder.buyTab3:clear()
	StationFounder.buyTab4:clear()

	StationFounder.buildMiscStationGui(StationFounder.buyTab4, textBox.text)
    StationFounder.buildFactoryGui({0}, StationFounder.buyTab0, textBox.text)
    StationFounder.buildFactoryGui({1, 2, 3}, StationFounder.buyTab1, textBox.text)
    StationFounder.buildFactoryGui({4, 5, 6}, StationFounder.buyTab2, textBox.text)
    StationFounder.buildFactoryGui({7, 8, 9}, StationFounder.buyTab3, textBox.text)
end