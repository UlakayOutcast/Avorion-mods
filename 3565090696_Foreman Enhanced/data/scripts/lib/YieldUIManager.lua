local YieldUIManager = {}

-- Debug flag - set to true to enable debug output
local DEBUG_YIELD = false

-- Debug print function
local function debugPrint(...)
    if DEBUG_YIELD then
        print("Foreman:", ...)
    end
end
local yieldWindow = nil
local yieldHeaderLabel = nil
local yieldAccuracyLabel = nil
local yieldAsteroidCountLabel = nil
local yieldSalvageCountLabel = nil
local yieldNameLabels = {}
local yieldValueLabels = {}
local yieldRowButtons = {}

function YieldUIManager.ensureYieldUI(uiContainer, miningFilters)
    if yieldWindow then return end
    if not uiContainer then return end
    yieldWindow = uiContainer:createContainer(Rect(5, 340, 295, 465))
    yieldWindow:createFrame(Rect(0, 0, 290, 125))
    yieldHeaderLabel = yieldWindow:createLabel(Rect(5, 2, 200, 18), "Yields"%_t, 13)
    yieldHeaderLabel:setLeftAligned()
    yieldAccuracyLabel = yieldWindow:createLabel(Rect(5, 18, 200, 32), ""%_t, 12)
    yieldAccuracyLabel:setLeftAligned()
    yieldAsteroidCountLabel = yieldWindow:createLabel(Rect(200, 2, 290, 18), "Asteroids: 0"%_t, 11)
    yieldAsteroidCountLabel:setRightAligned()
    yieldSalvageCountLabel = yieldWindow:createLabel(Rect(200, 18, 290, 32), "Salvage: 0"%_t, 11)
    yieldSalvageCountLabel:setRightAligned()
    local leftX = 8
    local rightX = 153
    local rowH = 14
    local startY = 34
    -- Only initialize filters to true if they are completely uninitialized (all nil)
    -- This prevents overriding user settings when the UI is recreated
    local allNil = true
    for i = 0, 6, 1 do
        if miningFilters[i] ~= nil then
            allNil = false
            break
        end
    end
    if allNil then
        for i = 0, 6, 1 do
            miningFilters[i] = true
        end
    end
    for i = 0, 6, 1 do
        local columnX = (i % 2 == 0) and leftX or rightX
        local rowY = startY + math.floor(i / 2) * rowH
        local nameLabel = yieldWindow:createLabel(Rect(columnX, rowY, columnX + 72, rowY + rowH), Material(i).name .. ":", 11)
        nameLabel:setLeftAligned()
        yieldNameLabels[i] = nameLabel
        local valueLabel = yieldWindow:createLabel(Rect(columnX + 72, rowY, columnX + 137, rowY + rowH), "-", 11)
        valueLabel:setRightAligned()
        yieldValueLabels[i] = valueLabel
        local fnName = "onYieldRowClickedIdx" .. tostring(i)
        local btn = yieldWindow:createButton(Rect(columnX - 2, rowY - 1, columnX + 139, rowY + rowH + 1), " ", fnName)
        btn.textSize = 1
        btn.active = true
        btn.tooltip = "Toggle filter for " .. Material(i).name
        btn.layer = 20
        yieldRowButtons[i] = btn
    end
    yieldWindow:show()
end
function YieldUIManager.getYieldWindow()
    return yieldWindow
end
function YieldUIManager.getYieldHeaderLabel()
    return yieldHeaderLabel
end
function YieldUIManager.getYieldAccuracyLabel()
    return yieldAccuracyLabel
end
function YieldUIManager.getYieldAsteroidCountLabel()
    return yieldAsteroidCountLabel
end
function YieldUIManager.getYieldSalvageCountLabel()
    return yieldSalvageCountLabel
end
function YieldUIManager.updateSalvageCount(getSalvageTargetCountCallback)
    if yieldSalvageCountLabel then
        local salvageCount = getSalvageTargetCountCallback and getSalvageTargetCountCallback() or 0
        yieldSalvageCountLabel.caption = "Salvage: " .. tostring(salvageCount or 0)
    end
end
function YieldUIManager.clearSalvageCount()
    if yieldSalvageCountLabel then
        yieldSalvageCountLabel.caption = "Salvage: --"
    end
end
function YieldUIManager.getYieldNameLabels()
    return yieldNameLabels
end
function YieldUIManager.getYieldValueLabels()
    return yieldValueLabels
end
function YieldUIManager.getYieldRowButtons()
    return yieldRowButtons
end
function YieldUIManager.toggleYieldWindow(uiContainer, miningFilters, yieldVisiblePreference, saveAutomationSettingsCallback)
    YieldUIManager.ensureYieldUI(uiContainer, miningFilters)
    if yieldWindow.visible then
        yieldWindow:hide()
        yieldVisiblePreference = false
    else
        yieldWindow:show()
        yieldVisiblePreference = true
    end
    if saveAutomationSettingsCallback then
        saveAutomationSettingsCallback()
    end
    return yieldVisiblePreference
end
function YieldUIManager.updateYieldUI(totalAmount, asteroidCount, perOre, window, uiContainer, sectorScanned, shipHasForemanSystem, yieldVisiblePreference, scanAccuracy, miningFilters, getSalvageTargetCountCallback)
    if not window or not uiContainer then return end
    YieldUIManager.ensureYieldUI(uiContainer, miningFilters)

    -- Always respect the user's visibility preference; don't auto-hide on missing scan/system
    if yieldWindow then
        if yieldVisiblePreference then yieldWindow:show() else yieldWindow:hide() end
    end

    -- Update counts (show placeholders when data isn't available yet)
    if yieldAsteroidCountLabel then
        local asteroidText = (sectorScanned and shipHasForemanSystem) and tostring(asteroidCount or 0) or "--"
        yieldAsteroidCountLabel.caption = "Asteroids: " .. asteroidText
    end
    -- Update header with total amount if available, otherwise keep title
    if yieldHeaderLabel then
        local showTotal = (sectorScanned and shipHasForemanSystem) and (totalAmount ~= nil)
        if showTotal then
            yieldHeaderLabel.caption = "Yields: " .. toReadableNumber(totalAmount or 0, 1)
        else
            yieldHeaderLabel.caption = "Yields"%_t
        end
    end
    if yieldSalvageCountLabel and getSalvageTargetCountCallback then
        local salvageCount = getSalvageTargetCountCallback()
        yieldSalvageCountLabel.caption = "Salvage: " .. tostring(salvageCount or 0)
    end

    if yieldRowButtons and getTableLength(yieldRowButtons) == 7 then
        for i = 0, 6, 1 do
            local btn = yieldRowButtons[i]
            if btn then
                btn.active = true
                btn.visible = true
                btn.layer = 20
            end
        end
    end

    local acc = (sectorScanned and shipHasForemanSystem) and (scanAccuracy or -1) or -1
    if acc == -1 then
        yieldAccuracyLabel.caption = ""%_t
        for i = 0, 6, 1 do
            yieldNameLabels[i].caption = Material(i).name .. ":"
            yieldValueLabels[i].caption = "-"
        end
    elseif acc == 0 then
        yieldAccuracyLabel.caption = "Accuracy: Yes/No"%_t
        for i = 0, 6, 1 do
            yieldNameLabels[i].caption = Material(i).name .. ":"
            yieldValueLabels[i].caption = "-"
        end
    elseif acc == 1 then
        yieldAccuracyLabel.caption = "Accuracy: Asteroid count"%_t
        for i = 0, 6, 1 do
            yieldNameLabels[i].caption = Material(i).name .. ":"
            yieldValueLabels[i].caption = "?"
        end
    elseif acc == 2 then
        yieldAccuracyLabel.caption = "Accuracy: Estimated"%_t
        for i = 0, 6, 1 do
            local est = 0
            if perOre and perOre[i] then est = perOre[i] end
            local estText = UtilityFunctions.getOreAmountEstimate(est)
            yieldNameLabels[i].caption = Material(i).name .. ":"
            yieldValueLabels[i].caption = "~" .. tostring(estText)
        end
    elseif acc == 3 then
        -- Show estimated per-ore values instead of question marks after scan
        yieldAccuracyLabel.caption = "Accuracy: Estimated"%_t
        for i = 0, 6, 1 do
            local est = 0
            if perOre and perOre[i] then est = perOre[i] end
            local estText = UtilityFunctions.getOreAmountEstimate(est)
            yieldNameLabels[i].caption = Material(i).name .. ":"
            yieldValueLabels[i].caption = "~" .. tostring(estText)
        end
    elseif acc == 4 then
        yieldAccuracyLabel.caption = "Accuracy: Exact"%_t
        for i = 0, 6, 1 do
            local val = 0
            if perOre and perOre[i] then val = perOre[i] end
            yieldNameLabels[i].caption = Material(i).name .. ":"
            yieldValueLabels[i].caption = toReadableNumber(val, 1)
        end
    end

    for i = 0, 6, 1 do
        local enabled = miningFilters[i]
        yieldNameLabels[i].color = enabled and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        yieldValueLabels[i].color = ColorRGB(1,1,1)
    end
end
local yieldLastClickIndex = nil
local yieldLastClickTime = 0
function YieldUIManager.onYieldRowClickedIndex(materialIndex, miningFilters, scanAccuracy, syncMiningFilterToServerCallback, invalidateAsteroidCacheOnFilterChangeCallback, getMineableAmountInVicinityCallback, updateYieldUICallback, fm)
    if materialIndex == nil then return end
    local onlyThis = false
    local now = os.clock()
    if yieldLastClickIndex == materialIndex and (now - yieldLastClickTime) < 0.35 then
        onlyThis = true
    end
    yieldLastClickIndex = materialIndex
    yieldLastClickTime = now
    local cbFunctionNames = {
        [0] = "onIronChecked",
        [1] = "onTitaniumChecked",
        [2] = "onNaoniteChecked",
        [3] = "onTriniumChecked",
        [4] = "onXanionChecked",
        [5] = "onOgoniteChecked",
        [6] = "onAvorionChecked",
    }
    if onlyThis then
        for i = 0, 6, 1 do
            local fn = cbFunctionNames[i]
            if fn and fm[fn] then
                fm[fn](nil, i == materialIndex)
                invokeServerFunction(fn, nil, i == materialIndex)
            else
                miningFilters[i] = (i == materialIndex)
                syncMiningFilterToServerCallback(i, (i == materialIndex))
            end
        end
    else
        local newVal = not miningFilters[materialIndex]
        local fn = cbFunctionNames[materialIndex]
        if fn and fm[fn] then
            fm[fn](nil, newVal)
            invokeServerFunction(fn, nil, newVal)
        else
            miningFilters[materialIndex] = newVal
            syncMiningFilterToServerCallback(materialIndex, newVal)
        end
    end
    for i = 0, 6, 1 do
        local enabled = miningFilters[i]
        if yieldNameLabels[i] then
            yieldNameLabels[i].color = enabled and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        end
    end
    invalidateAsteroidCacheOnFilterChangeCallback()
    -- Automatically restart mining when filters change to apply new settings
    if onClient() then
        invokeServerFunction("restartMiningOnFilterChange", Player().craft.factionIndex)
    end
    local wantsPerOre = (scanAccuracy == 4) or (scanAccuracy == 2)
    local total, cnt, per = getMineableAmountInVicinityCallback(true, wantsPerOre)
    updateYieldUICallback(total, cnt, (wantsPerOre and per) or nil)
end
local oreTooltips = {
    [0]="Filter Iron"%_t,
    [1]="Filter Titanium"%_t,
    [2]="Filter Naonite"%_t,
    [3]="Filter Trinium"%_t,
    [4]="Filter Xanion"%_t,
    [5]="Filter Ogonite"%_t,
    [6]="Filter Avorion"%_t
}
function YieldUIManager.setMiningAmountLabelText(resourcesToMine, asteroidCount, resources, scanAccuracy, filterCheckBoxes)
    if scanAccuracy == 4 and resources ~= nil and filterCheckBoxes ~= nil then
        for i, v in pairs(filterCheckBoxes) do
            v.tooltip = oreTooltips[i]..": "..toReadableNumber(resources[i], 1)
        end
    end
end
function YieldUIManager.forceAsteroidCountUpdate(factionIndex, shipHasForemanSystem, sectorScanned, mineableCache, scanAccuracy, getMineableAmountInVicinityCallback, updateYieldUICallback)
    if not shipHasForemanSystem or not sectorScanned then return end
    if mineableCache then
        mineableCache.t = 0 -- Force cache miss
    end
    local wantsPerOre = (scanAccuracy == 4) or (scanAccuracy == 2)
    local resourcesLeftTotal, asteroidCount, resources = getMineableAmountInVicinityCallback(true, wantsPerOre)
    updateYieldUICallback(resourcesLeftTotal, asteroidCount, (wantsPerOre and resources) or nil)
end
function YieldUIManager.updateYieldUIAfterScan(scanAccuracy, getMineableAmountInVicinityCallback, updateYieldUICallback)
    local wantsPerOre = (scanAccuracy == 4) or (scanAccuracy == 2)
    local resourcesLeftTotal, asteroidCount, resources = getMineableAmountInVicinityCallback(true, wantsPerOre)
    -- Debug output to help diagnose yield issues
    debugPrint("updateYieldUIAfterScan - scanAccuracy:", scanAccuracy, "wantsPerOre:", wantsPerOre, "total:", resourcesLeftTotal, "count:", asteroidCount)
    if resources then
        for i = 0, 6 do
            if resources[i] and resources[i] > 0 then
                debugPrint("Material", i, "amount:", resources[i])
            end
        end
    end
    updateYieldUICallback(resourcesLeftTotal, asteroidCount, (wantsPerOre and resources) or nil)
end
return YieldUIManager
