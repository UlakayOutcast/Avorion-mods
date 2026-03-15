-- include("lib/persistence")

-- namespace FleetStatus
FleetStatus = {}

local fs = FleetStatus

fs.entity_id = nil
fs._hud_shieldBlue = nil
fs._hud_durabilityGreen = nil
fs._hud_durabilityLow = nil
fs._hud_durabilityCritical = nil
fs._hud_white = nil
fs._menu_white = ColorRGB(1.0, 1.0, 1.0)
fs._persistence = nil
fs._config_save_location = ""
fs._populate_necessary = true
fs._config_stale = true
fs.config = {}
local STEP = 10
local persistence = nil

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- API-defined methods
-- ~~~~~~~~~~~~~~~~~~~~~~~~

function fs.initialize(...)
    if onClient() then
        local entity = Entity()
        if valid(entity) then
            fs.entity_id = entity.id
        end

        local player = Player()
        if valid(player) then
            player:registerCallback("onPreRenderHud", "renderShipStatus")
            player:registerCallback("onShipChanged", "loadToShip")

            -- we need to separate the configs for each galaxy the user loads, but the game
            -- doesn't provide UUIDs. so I'm using game seed, hoping that is unique enough.
            -- this line is still a hack, because I don't know how to make the mixed-case seed strings
            -- so I'm base64-ing the string representation of a double
            fs._config_save_location = "moddata/" .. fs.base64_enc(tostring(GameSeed().value)) .. "_fss_config.lua"

            fs._persistence = persistence
            fs.LoadConfigs()

            fs._hud_shieldBlue = ColorARGB(fs.config.opacity, 0.01, 0.66, 0.96)
            fs._hud_durabilityGreen = ColorARGB(fs.config.opacity, 0.02, 1.0, 0.29)
            fs._hud_durabilityLow = ColorARGB(fs.config.opacity, 1.0, 0.65, 0.0)
            fs._hud_durabilityCritical = ColorARGB(fs.config.opacity, 1.0, 0.0, 0.0)
            fs._hud_durabilityCritical = ColorARGB(fs.config.opacity, 1.0, 0.0, 0.0)
            fs._hud_white = ColorARGB(fs.config.opacity, 1.0, 1.0, 1.0)

            local menu = ScriptUI()
            local res = getResolution()
            local size = vec2(1200, 650)

            fs.window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
            fs.window.caption = "Fleet Ship Status"
            fs.window.showCloseButton = 1
            fs.window.moveable = 1
            menu:registerWindow(fs.window, "FSS")
        end
    end

end

-- this method is used to determine when to show the prompt for the settings window 'FSS'
-- if you want to only show the prompt in the top-right shift menu, you have to
-- have to return false in any case where the caller isn't the player's current ship
function fs.interactionPossible(playerIndex, option)
    local ship = Entity()
    local player = Player(playerIndex)

    local craft = player.craft
    if craft == nil then
        return false
    end

    if ship.index == craft.index then
        return true
    end

    return false
end

function fs.getIcon()
    return "data/textures/icons/fss.png"
end

function fs.initUI()
    local container = fs.window:createContainer(Rect(vec2(0, 0), fs.window.size))
    local outerSplit = UIVerticalSplitter(Rect(vec2(0, 0), fs.window.size), 10, 10, 0.4)

    -------------------------------- left

    --label and on/off toggle split
    local LeftPanelSettingsSplit = UIHorizontalSplitter(outerSplit.left, 2, 2, 0.05)
    local ShipsLabelsPadding = UIHorizontalSplitter(LeftPanelSettingsSplit.top, 10, 10, 1.0)
    local SettingsLabel = container:createLabel(ShipsLabelsPadding.top, "Settings", 16)
    SettingsLabel.underlined = true

    local AllSettingsArea = UIVerticalLister(ShipsLabelsPadding.bottom, 25, 25)
    AllSettingsArea.marginTop = 20

    -- enableHUD checkbox
    fs.EnableHUDCheckbox = container:createCheckBox(AllSettingsArea:nextRect(15), "Enable Fleet Status in Hud", 'onEnableHUD')
    fs.EnableHUDCheckbox.bold = true
    fs.EnableHUDCheckbox.fontSize = 16
    if fs.config.enabled then fs.EnableHUDCheckbox.setCheckedNoCallback(fs.EnableHUDCheckbox, true) end

    -- enableHUD checkbox
    fs.ShowLocationsCheckbox = container:createCheckBox(AllSettingsArea:nextRect(10), "Show Ship Locations", 'onEnableShipLocations')
    fs.ShowLocationsCheckbox.bold = false
    fs.ShowLocationsCheckbox.fontSize = 15
    if fs.config.showLocation then fs.ShowLocationsCheckbox.setCheckedNoCallback(fs.ShowLocationsCheckbox, true) end

    -- enableHUD checkbox
    fs.ShowCargoCheckbox = container:createCheckBox(AllSettingsArea:nextRect(10), "Show Ship Cargo Percentage", 'onEnableShipCargo')
    fs.ShowCargoCheckbox.bold = false
    fs.ShowCargoCheckbox.fontSize = 15
    if fs.config.showCargo then fs.ShowCargoCheckbox.setCheckedNoCallback(fs.ShowCargoCheckbox, true) end

    -- HUD opacity slider
    AllSettingsArea:nextRect(0) -- spacer
    fs.opacitySlider = container:createSlider(AllSettingsArea:nextRect(45), 0, 100, 20, "HUD Opacity", "onSliderChanged")
    fs.opacitySlider:setSliderPositionNoCallback(fs.config.opacity)

    -- move ships in/out of HUD buttons
    AllSettingsArea:nextRect(0) -- spacer
    local shiftToHud = container:createButton(AllSettingsArea:nextRect(40), "<< All Ships to HUD", "onAllToHUDButton")
    local shiftToAvailable = container:createButton(AllSettingsArea:nextRect(40), "All Ships Out of HUD >>", "onAllToAvailableButton")

    -- move HUD label
    AllSettingsArea:nextRect(0) -- spacer
    local moveHUDLabel = container:createLabel(AllSettingsArea:nextRect(15), "Move HUD", 16)
    moveHUDLabel.underlined = true

    -- move HUD arrow buttons
    local MoveButtonsGrid = UIGridSplitter(AllSettingsArea:nextRect(140), 10, 10, 3, 3)
    local upButton = container:createButton(MoveButtonsGrid:partition(1, 0), "↑", "onUpButton")
    local downButton = container:createButton(MoveButtonsGrid:partition(1, 2), "↓", "onDownButton")
    local leftButton = container:createButton(MoveButtonsGrid:partition(0, 1), "←", "onLeftButton")
    local rightButton = container:createButton(MoveButtonsGrid:partition(2, 1), "→", "onRightButton")

    -------------------------------- right

    -- ship list labels
    local ShipsListAndLabelsSplit = UIHorizontalSplitter(outerSplit.right, 2, 2, 0.05)
    local ShipsLabelsSplit = UIVerticalSplitter(ShipsListAndLabelsSplit.top, 10, 10, 0.5)
    local hudShipListLabel = container:createLabel(ShipsLabelsSplit.left, 'Show in HUD', 16)
    hudShipListLabel.underlined = true
    local otherShipListLabel = container:createLabel(ShipsLabelsSplit.right, 'Available Ships', 16)
    otherShipListLabel.underlined = true

    local ShipsSplit = UIVerticalSplitter(ShipsListAndLabelsSplit.bottom, 5, 5, 0.5)

    -- ships in HUD list
    fs.hudShipListBox = fs.window:createListBoxEx(ShipsSplit.left)
    fs.hudShipListBox.columns = 1
    fs.hudShipListBox:setColumnWidth(0, 200)
    fs.hudShipListBox.onSelectFunction = "onHudShipListSelect"

    -- available ships list
    fs.otherShipListBox = fs.window:createListBoxEx(ShipsSplit.right)
    fs.otherShipListBox.columns = 1
    fs.otherShipListBox:setColumnWidth(0, 200)
    fs.otherShipListBox.onSelectFunction = "onOtherShipListSelect"
end

function fs.update(timeStep)
    local player = Player()
    if fs.entity_id == nil or player.craft == nil or fs.entity_id ~= player.craft.id then
        fs._populate_necessary = true
        return
    end

    if fs._populate_necessary then
        fs.LoadConfigs()
        fs.ResetColors()
        fs.PopulateShipList()
        fs._populate_necessary = false
    end

    if not fs.window.visible then return end

    if fs.config.enabled then fs.EnableHUDCheckbox.setCheckedNoCallback(fs.EnableHUDCheckbox, true) end
    fs.opacitySlider:setSliderPositionNoCallback(fs.config.opacity)

    fs.hudShipListBox:clear()
    fs.otherShipListBox:clear()

    for _, ship in pairs(fs.config["ships"]) do
        local useList = nil
        if ship.selected then
            useList = fs.hudShipListBox
        else
            useList = fs.otherShipListBox
        end
        useList:addRow(ship.name)
        useList:setEntry(0, useList.size - 1, ship.name, false, false, fs._menu_white)
        useList:setEntryType(0, useList.size - 1, ListBoxEntryType.Text)
    end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- Callback methods
-- ~~~~~~~~~~~~~~~~~~~~~~~~

function fs.loadToShip(playerIndex, craftId)
    local ship = Entity(craftId)
    ship:addScriptOnce("entity/fleetstatus.lua")
end

function fs.onUpButton(button)
    if fs.config.y_origin - STEP < 0 then return end
    fs.config.y_origin = fs.config.y_origin - STEP
    fs.SaveConfigs()
end

function fs.onDownButton(button)
    if fs.config.y_origin + STEP >= getResolution().y then return end
    fs.config.y_origin = fs.config.y_origin + STEP
    fs.SaveConfigs()
end

function fs.onLeftButton(button)
    if fs.config.x_origin - STEP < 0 then return end
    fs.config.x_origin = fs.config.x_origin - STEP
    fs.SaveConfigs()
end

function fs.onRightButton(button)
    if fs.config.x_origin + STEP >= getResolution().x then return end
    fs.config.x_origin = fs.config.x_origin + STEP
    fs.SaveConfigs()
end

function fs.onSliderChanged(slider)
    fs.config.opacity = slider.value / 100
    fs.ResetColors()
    fs.SaveConfigs()
end

function fs.onAllToAvailableButton(button)
    for k, _ in pairs(fs.config.ships) do
        fs.config.ships[k].selected = false
    end
    fs.SaveConfigs()
end

function fs.onAllToHUDButton(button)
    for k, _ in pairs(fs.config.ships) do
        fs.config.ships[k].selected = true
    end
    fs.SaveConfigs()
end

function fs.onHudShipListSelect(index, value)
    if not value or value == "" then return end

    fs.config.ships[value].selected = false
    fs.SaveConfigs()
end

function fs.onOtherShipListSelect(index, value)
    if not value or value == "" then return end

    fs.config.ships[value].selected = true
    fs.SaveConfigs()
end

function fs.onEnableHUD(checkbox, value)
    if value then
        fs.config["enabled"] = true
    else
        fs.config["enabled"] = false
    end

    fs.SaveConfigs()
end

function fs.onEnableShipLocations(checkbox, value)
    if value then
        fs.config["showLocation"] = true
    else
        fs.config["showLocation"] = false
    end

    fs.SaveConfigs()
end

function fs.onEnableShipCargo(checkbox, value)
    if value then
        fs.config["showCargo"] = true
    else
        fs.config["showCargo"] = false
    end

    fs.SaveConfigs()
end

function fs.renderShipStatus()
    if not fs.config.enabled then return end

    local player = Player()
    if player.state ~= PlayerStateType.Fly then return end

    if fs.entity_id == nil or player.craft == nil or fs.entity_id ~= player.craft.id then
        -- if we get here then some other FSS scipt is messing
        -- with the configs. need to mark as stale

        fs._config_stale = true
        return
    end

    -- if we get here and it's stale, it means we just got focus for the first time in a while
    if fs._config_stale then fs.LoadConfigs() end

    local y_offset = 75
    for _, shipData in pairs(fs.config.ships) do
        -- skip if it's not supposed to be shown on the hud
        if fs.config.ships ~= nil and fs.config.ships[shipData.name].selected == false then goto continue end

        -- skip the player's current ships since they already have the health bar at the bottom
        if player.craft.name == shipData.name then goto continue end

        local entry = ShipDatabaseEntry(shipData.faction, shipData.name)

        fs._drawShipStatus(entry, y_offset)
        y_offset = y_offset + 75
        ::continue::
    end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- Helper/private methods
-- ~~~~~~~~~~~~~~~~~~~~~~~~

function fs._drawShipStatus(entry, y_offset)
    local _, durability_perc, _, _, _ = entry:getDurabilityProperties()
    local _, shields_perc = entry:getShields()
    local str = entry.name

    if fs.config.showLocation then
        local x, y = entry:getCoordinates()
        str = str .. " (" .. tostring(x) .. ", " .. tostring(y) .. ")"
    end

    if fs.config.showCargo then
        local _, cargoCap = entry:getCargo()
        if cargoCap ~= 0 then
            local cargoCurr = entry:getFreeCargoSpace()
            local cargoPerc = string.format(" (%.2f%%)", (100 * (cargoCap - cargoCurr) / cargoCap))
            -- local cargoPerc = string.format(" %f  --  %f", cargoCap - cargoCurr, cargoCap)
            str = str .. cargoPerc --" (" .. cargoPerc .. "%)"
        end
    end

    local res = getResolution()

    if y_offset > res.y then
        return
    end

    local xmark = fs.config.x_origin
    local ymark = fs.config.y_origin + y_offset

    local renderer = UIRenderer()
    drawText(
        str,
        xmark + 5,
        ymark - 22,
        fs._hud_white, -- white text
        12, --font size 
        0, -- not bolded
        0, -- not itilicized
        2 -- outlined
    )
    if shields_perc > 0.0 then
        renderer:renderRect(
            vec2(xmark + 5, ymark + 2),
            vec2(xmark + 5 + 200 * shields_perc, ymark + 25),
            fs._hud_shieldBlue,
            1
        )
        renderer:renderBorder(
            vec2(xmark + 5, ymark + 2),
            vec2(xmark + 5 + 200 * shields_perc, ymark + 25),
            fs._hud_shieldBlue,
            1
        )
    end

    if durability_perc > 0.0 then
        local color = fs._hud_durabilityGreen
        if durability_perc <= 0.25 then
            color = fs._hud_durabilityCritical
        elseif durability_perc <= 0.5 then
            color = fs._hud_durabilityLow
        end

        renderer:renderRect(
            vec2(xmark + 6, ymark + 9),
            vec2(xmark + 5 + 199.5 * durability_perc, ymark + 18),
            color,
            1
        )
        renderer:renderBorder(
            vec2(xmark + 6, ymark + 9),
            vec2(xmark + 5 + 199.5 * durability_perc, ymark + 18),
            color,
            1
        )
    end

    renderer:display()
end

function fs.SaveConfigs()
    fs._persistence.store(fs._config_save_location, fs.config)
end

function fs.LoadConfigs()
    local file,err = io.open(fs._config_save_location, "r")
    if err then
        printlog("Failed to load configs from disk, loading defaults: " .. err)
        fs.LoadDefaultConfigs()
        return nil
    end
    local rtn = loadstring(file:read("*a"))()
    file:close()

    fs.config = rtn
    if fs.config.showCargo == nil then fs.config.showCargo = false end
    if fs.config.showLocation == nil then fs.config.showLocation = true end
    fs._config_stale = false
end

function fs.LoadDefaultConfigs()
    fs.config = {
        ["enabled"] = false,
        ["ships"] = {},
        ["opacity"] = 0.6,
        ["x_origin"] = 0,
        ["y_origin"] = 0,
        ["showLocation"] = true,
        ["showCargo"] = false
    }

    fs.PopulateShipList()
    fs.SaveConfigs()
end

function fs.PopulateShipList()
    local allShips = {}
    local player = Player()
    local alliance = Alliance(player.allianceIndex)
    local allianceShips = {}
    if valid(alliance) then
        allianceShips = {alliance:getShipNames()}
    end

    local playerShips = {player:getShipNames()}

    for _, ship in ipairs(allianceShips) do
        local entry = ShipDatabaseEntry(player.allianceIndex, ship)
        local type = entry:getEntityType()

        if type ~= EntityType.Ship and type ~= EntityType.Station then
            goto continueA
        end

        local selected = false
        if fs.config["ships"][ship] ~= nil then
            selected = fs.config["ships"][ship]["selected"]
        end

        allShips[entry.name] = {["name"] = entry.name, ["faction"] = entry.faction, ["selected"] = selected}
        ::continueA::
    end

    for _, ship in ipairs(playerShips) do
        local entry = ShipDatabaseEntry(player.index, ship)
        local type = entry:getEntityType()

        if type ~= EntityType.Ship and type ~= EntityType.Station then
            goto continueB
        end

        local selected = false
        if fs.config["ships"][ship] ~= nil then
            selected = fs.config["ships"][ship]["selected"]
        end

        allShips[entry.name] = {["name"] = entry.name, ["faction"] = entry.faction, ["selected"] = selected}
        ::continueB::
    end

    fs.config["ships"] = allShips
    fs.SaveConfigs()
end

function fs.ResetColors()
    fs._hud_shieldBlue = ColorARGB(fs.config.opacity, 0.01, 0.66, 0.96)
    fs._hud_durabilityGreen = ColorARGB(fs.config.opacity, 0.02, 1.0, 0.29)
    fs._hud_durabilityLow = ColorARGB(fs.config.opacity, 1.0, 0.65, 0.0)
    fs._hud_durabilityCritical = ColorARGB(fs.config.opacity, 1.0, 0.0, 0.0)
    fs._hud_white = ColorARGB(fs.config.opacity, 1.0, 1.0, 1.0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- Libraries
-- ~~~~~~~~~~~~~~~~~~~~~~~~

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function fs.base64_enc(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local write, writeIndent, writers, refCount;

persistence =
{
	store = function (path, ...)
		local file, e = io.open(path, "w");
		if not file then
			return error(e);
		end
		local n = select("#", ...);
		-- Count references
		local objRefCount = {}; -- Stores reference that will be exported
		for i = 1, n do
			refCount(objRefCount, (select(i,...)));
		end;
		-- Export Objects with more than one ref and assign name
		-- First, create empty tables for each
		local objRefNames = {};
		local objRefIdx = 0;
		file:write("-- Persistent Data\n");
		file:write("local multiRefObjects = {\n");
		for obj, count in pairs(objRefCount) do
			if count > 1 then
				objRefIdx = objRefIdx + 1;
				objRefNames[obj] = objRefIdx;
				file:write("{};"); -- table objRefIdx
			end;
		end;
		file:write("\n} -- multiRefObjects\n");
		-- Then fill them (this requires all empty multiRefObjects to exist)
		for obj, idx in pairs(objRefNames) do
			for k, v in pairs(obj) do
				file:write("multiRefObjects["..idx.."][");
				write(file, k, 0, objRefNames);
				file:write("] = ");
				write(file, v, 0, objRefNames);
				file:write(";\n");
			end;
		end;
		-- Create the remaining objects
		for i = 1, n do
			file:write("local ".."obj"..i.." = ");
			write(file, (select(i,...)), 0, objRefNames);
			file:write("\n");
		end
		-- Return them
		if n > 0 then
			file:write("return obj1");
			for i = 2, n do
				file:write(" ,obj"..i);
			end;
			file:write("\n");
		else
			file:write("return\n");
		end;
		if type(path) == "string" then
			file:close();
		end;
	end;

	load = function (path)
		local f, e;
		if type(path) == "string" then
			f, e = loadfile(path);
		else
			f, e = path:read('*a')
		end
		if f then
			return f();
		else
			return nil, e;
		end;
	end;
}

-- write thing (dispatcher)
write = function (file, item, level, objRefNames)
	writers[type(item)](file, item, level, objRefNames);
end;

-- write indent
writeIndent = function (file, level)
	for i = 1, level do
		file:write("\t");
	end;
end;

-- recursively count references
refCount = function (objRefCount, item)
	-- only count reference types (tables)
	if type(item) == "table" then
		-- Increase ref count
		if objRefCount[item] then
			objRefCount[item] = objRefCount[item] + 1;
		else
			objRefCount[item] = 1;
			-- If first encounter, traverse
			for k, v in pairs(item) do
				refCount(objRefCount, k);
				refCount(objRefCount, v);
			end;
		end;
	end;
end;

-- Format items for the purpose of restoring
writers = {
	["nil"] = function (file, item)
			file:write("nil");
		end;
	["number"] = function (file, item)
			file:write(tostring(item));
		end;
	["string"] = function (file, item)
			file:write(string.format("%q", item));
		end;
	["boolean"] = function (file, item)
			if item then
				file:write("true");
			else
				file:write("false");
			end
		end;
	["table"] = function (file, item, level, objRefNames)
			local refIdx = objRefNames[item];
			if refIdx then
				-- Table with multiple references
				file:write("multiRefObjects["..refIdx.."]");
			else
				-- Single use table
				file:write("{\n");
				for k, v in pairs(item) do
					writeIndent(file, level+1);
					file:write("[");
					write(file, k, level+1, objRefNames);
					file:write("] = ");
					write(file, v, level+1, objRefNames);
					file:write(";\n");
				end
				writeIndent(file, level);
				file:write("}");
			end;
		end;
	["function"] = function (file, item)
			-- Does only work for "normal" functions, not those
			-- with upvalues or c functions
			local dInfo = debug.getinfo(item, "uS");
			if dInfo.nups > 0 then
				file:write("nil --[[functions with upvalue not supported]]");
			elseif dInfo.what ~= "Lua" then
				file:write("nil --[[non-lua function not supported]]");
			else
				local r, s = pcall(string.dump,item);
				if r then
					file:write(string.format("loadstring(%q)", s));
				else
					file:write("nil --[[function could not be dumped]]");
				end
			end
		end;
	["thread"] = function (file, item)
			file:write("nil --[[thread]]\n");
		end;
	["userdata"] = function (file, item)
			file:write("nil --[[userdata]]\n");
		end;
}