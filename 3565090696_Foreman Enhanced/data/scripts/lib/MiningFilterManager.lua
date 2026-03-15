local MiningFilterManager = {}

-- Debug flag for mining filter debugging
local MINING_FILTER_DEBUG = false

function MiningFilterManager.handleOreFilterChange(miningFilters, filterIndex, value, invalidateCacheFunc, syncToServerFunc)
    miningFilters[filterIndex] = value
    if invalidateCacheFunc then
        invalidateCacheFunc()
    end
    if syncToServerFunc then
        syncToServerFunc(filterIndex, value)
    end
end

function MiningFilterManager.onIronChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 0, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.onTitaniumChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 1, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.onNaoniteChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 2, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.onTriniumChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 3, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.onXanionChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 4, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.onOgoniteChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 5, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.onAvorionChecked(miningFilters, invalidateCacheFunc, syncToServerFunc, checkbox, value)
    MiningFilterManager.handleOreFilterChange(miningFilters, 6, value, invalidateCacheFunc, syncToServerFunc)
end

function MiningFilterManager.syncMiningFilterToServer(miningFilterIndex, value)
    if onClient() then
        if MINING_FILTER_DEBUG then
            print("[FILTER DEBUG] MiningFilterManager.syncMiningFilterToServer called - material: " .. miningFilterIndex .. ", value: " .. tostring(value))
        end
        local x, y = Sector():getCoordinates()
        invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "miningFilterChanged", Player().craft.factionIndex, miningFilterIndex, value)
    end
end


return MiningFilterManager
