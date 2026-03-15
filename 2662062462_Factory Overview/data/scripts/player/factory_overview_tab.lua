package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/galaxy/?.lua"
include ("callable")
include ("utility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace FactoryOverview
FactoryOverview = {}
local self = FactoryOverview
local all_check

if onClient() then
	function FactoryOverview.initialize()
		local playerWindow = PlayerWindow()
	
    	self.tab = playerWindow:createTab("Factory Overview"%_t, "data/textures/icons/pay-crew.png", "Factory Overview"%_t)
		self.tab.onSelectedFunction = "clientFetchDataFromGalaxy"
		self.tab.onShowFunction = "clientFetchDataFromGalaxy"		
		playerWindow:moveTabToTheRight(self.tab)
		FactoryOverview.buildWindow(self.tab)
		FactoryOverview.clientFetchDataFromGalaxy()
	end

	function FactoryOverview.refresh() 
		FactoryOverview.clientFetchDataFromGalaxy()
	end
end

function FactoryOverview.clientFetchDataFromGalaxy() 
	invokeServerFunction("fetchDataFromGalaxy", (all_check ~= nil and all_check.checked) )	
end

function FactoryOverview.fetchDataFromGalaxy(alliance_v) -- fetches the current and initial monetary data for each factory registered for the player
	if onClient() then
		invokeServerFunction("fetchDataFromGalaxy", alliance_v)	
		return
	end
	
	local galaxy = Galaxy()
	if not galaxy then
		print("Galaxy is not accessible from fetchDataFromGalaxy")
	else
		local av = alliance_v and (Player().alliance ~= nil)
		--print("Alliance: " .. tostring(Player().alliance ~= nil) .. " av: " .. tostring(av))
		local index = Player().index
		if av then
			index = Player().allianceIndex
		end
		--print("Index: " .. tostring(index) .. " av: " .. tostring(av))
		local errorcode, factories = galaxy:invokeFunction("factoryregister", "getFactoriesFor", index, av)
		
		if errorcode ~= 0 then
			print("Error while calling getFactoriesFor on Galaxy from Player: " .. tostring(errorcode))
			return 
		end

		invokeClientFunction(Player(callingPlayer), "loadData", factories)
	end

end
callable(FactoryOverview, "fetchDataFromGalaxy")

-- Declarations of the different literals and variables
local factory_ui_list  -- the ui element for showing the list
local sortingButtons = {} -- all the sorting buttons, this is used later to update the sorting arrows
local sortingLabels = {"Name"%_t, "Type"%_t, "Income"%_t, "Expense"%_t, "Profit"%_t, "Profit / h"%_t}

local selectedSorting = 5 -- which column do we use for sorting, same as sortingLabels
local sortingType = -1 -- ascending: 1 or descending: -1

local sortingFunctions = {} -- 
	sortingFunctions[1] = function(f1, f2) return f1['name'] < f2['name'] end
	sortingFunctions[-1] = function(f1, f2) return f1['name'] > f2['name'] end

	sortingFunctions[2] = function(f1, f2) return f1['title'] < f2['title'] end
	sortingFunctions[-2] = function(f1, f2) return f1['title'] > f2['title'] end

	sortingFunctions[3] = function(f1, f2) return f1['money_gained'] + f1['money_tax'] < f2['money_gained'] + f2['money_tax'] end
	sortingFunctions[-3] = function(f1, f2) return f1['money_gained'] + f1['money_tax'] > f2['money_gained'] + f2['money_tax'] end

	sortingFunctions[4] = function(f1, f2) return f1['money_spent'] < f2['money_spent'] end
	sortingFunctions[-4] = function(f1, f2) return f1['money_spent'] > f2['money_spent'] end

	sortingFunctions[5] = function(f1, f2) return f1['money_gained'] + f1['money_tax'] - f1['money_spent'] < f2['money_gained'] + f2['money_tax'] - f2['money_spent']  end
	sortingFunctions[-5] = function(f1, f2) return f1['money_gained'] + f1['money_tax'] - f1['money_spent'] > f2['money_gained'] + f2['money_tax'] - f2['money_spent']  end

	sortingFunctions[6] = function(f1, f2) return f1['profitability'] < f2['profitability'] end
	sortingFunctions[-6] = function(f1, f2) return f1['profitability'] > f2['profitability'] end

-- sets the sorting values and refreshes the table
function FactoryOverview.updateSorting(newSorting)
	if selectedSorting == newSorting then
		sortingType = sortingType * -1
	else
		selectedSorting = newSorting
		sortingType = 1
	end
	FactoryOverview.updateSortingIcons()
	FactoryOverview.loadData() -- reuses the existing data if no parameter is provided
end

--[[
The window should show a scrollable, sortable, table where each line is a factory, showing
name, type, income, expense, profit, profit/time (based on initial data)
Tooltip is working state, line data is location <- should use an id and look this up from stored data
]]--
function FactoryOverview.buildWindow(container) 

	local hsplit = UIHorizontalSplitter(Rect(container.size), 5, 5, 0.1)
	
	local margin = 10
	local b_width = (container.size.x - 2 * margin) / 6 -- should use the length of sortingLabels

	local refreshButton = container:createButton(Rect(hsplit.top.width - 40, 5, hsplit.top.width, hsplit.top.height - 25), "Refresh"%_t, "clientFetchDataFromGalaxy")
	refreshButton.icon = "data/textures/icons/refresh.png"
	refreshButton.tooltip = "Refresh Factory Data"%_t

	local gotoButton = container:createButton(Rect(hsplit.top.width - 85, 5, hsplit.top.width - 45, hsplit.top.height - 25), "Goto Selected"%_t, "gotoSelectedCoordinates")
	gotoButton.icon = "data/textures/icons/wire.png"
	gotoButton.tooltip = "Jump to selected station"%_t

	local separator = container:createLine(vec2(hsplit.top.width - 90, 0), vec2(hsplit.top.width-90, hsplit.top.height - 23))
	separator.color = ColorRGB(0.6, 0.6, 0.6)
	local separator2 = container:createLine(vec2(hsplit.top.width - 91, 0), vec2(hsplit.top.width-91, hsplit.top.height - 23))
	separator2.color = ColorRGB(0.6, 0.6, 0.6)
	
	container:createLabel(Rect(margin, 5, margin + 70, hsplit.top.height - 5), "Sorting: "%_t, 20)

	all_check = container:createCheckBox(Rect(hsplit.top.width - 197, 5, hsplit.top.width - 97, hsplit.top.height - 5), "Alliance: "%_t, "switchAllianceFlag")
	all_check.checked = false
	
	-- This is not the most beautiful solution, but I couldn't make clicking on the List Header work for this
	for ndx, sortingLabel in pairs(sortingLabels) do
		local sortingButton = container:createButton(
			Rect(margin + (ndx-1) * b_width + 2, hsplit.top.height - 20, margin + ndx * b_width - 3, hsplit.top.height),
			"", 
			"updateSorting"..tostring(ndx)
		)
		sortingButton.tooltip = "Sort by "%_t .. sortingLabel
		table.insert(sortingButtons, sortingButton)
	end

	FactoryOverview.updateSortingIcons()

	factory_ui_list = container:createListBoxEx(Rect(margin, hsplit.top.height, hsplit.bottom.width - 2*margin, hsplit.bottom.height))
	factory_ui_list.columns = 6 -- name, type, income, expense, profit, profit / hour, see sortingLabels
	factory_ui_list.rowHeight = 40


	for ndx=0, 5, 1 do
		factory_ui_list:setColumnWidth(ndx, b_width) 
	end

	factory_ui_list.headline = true -- to fix the first line as header
end

function FactoryOverview.switchAllianceFlag() 
	FactoryOverview.clientFetchDataFromGalaxy() 
end

local current_list -- stores the last data shown

-- populates the lines in the factory_ui_list based on the passed data or the list we used the last
function FactoryOverview.loadData(factory_list) 
	if not factory_ui_list then return end

	local list_to_use -- to enable reuse of the last data for sorting
	if not factory_list then
		if not current_list then return end
		list_to_use = current_list
	else
		list_to_use = factory_list
		current_list = factory_list
	end

	local sortedList = {}
	for _, val in pairs(list_to_use) do
		table.insert(sortedList, val)
	end

	table.sort(sortedList, sortingFunctions[selectedSorting * sortingType]) -- pick sorting function based on column and direction
	
	factory_ui_list:clear()
	local white = ColorRGB(1, 1, 1)
	local gray = ColorRGB(0.8, 0.8, 0.8)

	factory_ui_list:addRow() -- headline
	for ndx, sortingLabel in pairs(sortingLabels) do
		factory_ui_list:setEntryNoCallback(ndx-1, 0, sortingLabel, true, false, white)
	end

	for _, factory in pairs(sortedList) do
		local income = factory['money_gained'] + factory['money_tax']
		local profit = income - factory['money_spent']

		factory_ui_list:addRow(factory['location']) -- name, type, income, expense, profit, profit / hour
		factory_ui_list:setEntryNoCallback(0, factory_ui_list.rows-1, factory['name'], false, false, gray)
		factory_ui_list:setEntryNoCallback(1, factory_ui_list.rows-1, factory['title'], false, false, gray)
		factory_ui_list:setEntryNoCallback(2, factory_ui_list.rows-1, "${c}${money}"%_t % {c = credits(), money = createMonetaryString(income)} , false, false, gray)
		factory_ui_list:setEntryNoCallback(3, factory_ui_list.rows-1, "${c}${money}"%_t % {c = credits(), money = createMonetaryString(factory['money_spent'])} , false, false, gray)
		factory_ui_list:setEntryNoCallback(4, factory_ui_list.rows-1, "${c}${money}"%_t % {c = credits(), money = createMonetaryString(profit)}, false, false, gray )
		factory_ui_list:setEntryNoCallback(5, factory_ui_list.rows-1, "${c}${money}"%_t % {c = credits(), money = createMonetaryString(factory['profitability'])} , false, false, gray)
		factory_ui_list:setTooltip(factory_ui_list.rows-1, getRowTooltip(factory))
	end

end

-- is this really the only way to do this?! These functions receive the button as input, but that holds no information to help
function FactoryOverview.updateSorting1() FactoryOverview.updateSorting(1) end
function FactoryOverview.updateSorting2() FactoryOverview.updateSorting(2) end
function FactoryOverview.updateSorting3() FactoryOverview.updateSorting(3) end
function FactoryOverview.updateSorting4() FactoryOverview.updateSorting(4) end
function FactoryOverview.updateSorting5() FactoryOverview.updateSorting(5) end
function FactoryOverview.updateSorting6() FactoryOverview.updateSorting(6) end

-- sets the selected sorting button to an up or down arrow and the rest to empty
function FactoryOverview.updateSortingIcons() 
	for ndx, button in pairs(sortingButtons) do
		if ndx == selectedSorting then
			local icon
			if sortingType < 0 then 
				icon = "data/textures/icons/arrow-down2.png" 
			else 
				icon = "data/textures/icons/arrow-up2.png" 
			end
			button.icon = icon
		else
			button.icon = ""
		end
	end
end

-- parses the location from the original string
function FactoryOverview.getCoordinates(coo_string) -- assuming 15,-40 format
	local comma = coo_string:find(',')
	local x = tonumber(coo_string:sub(1, comma-1))
	local y = tonumber(coo_string:sub(comma+1))
	return x, y
end
	
-- Opens the Galaxy map and goes to the coordinates of the selected factory
function FactoryOverview.gotoSelectedCoordinates()
	if not factory_ui_list.selectedValue then return end

	local x, y = FactoryOverview.getCoordinates(factory_ui_list.selectedValue)

	GalaxyMap():setSelectedCoordinates(x, y)
	GalaxyMap():show(x, y)
end

-- Lists the percentage of time spent in different states of production, that is, Running vs. some error state
function getRowTooltip(factoryData) 
	local tooltip = ""

	if not factoryData['working_state'] then
		print("Factory data has no key called 'working_state' ")
		printTable(factoryData)
		return ""
	end

	for reason, percentage in pairs(factoryData['working_state']) do
		tooltip = tooltip .. string.format("%7s:  '%s'\n", percentage, reason)
	end

	return tooltip
end