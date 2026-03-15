local SalvageWorkAreaManager = {}
local UnifiedWreckageCache = include("UnifiedWreckageCache")

local WORK_AREA_CONFIG = {
    INITIAL_RADIUS = 300,
    EXPANSION_STEP = 150,
    MAX_RADIUS = 1500,
    MAX_SQUADS_PER_AREA = 1,
    RESOURCE_WEIGHT = 0.2,
    DISTANCE_WEIGHT = 1.0,
    MIN_RESOURCE_THRESHOLD = 10
}

local workAreas = {}
local squadAssignments = {}
local workAreaCounter = 0
local spatialGrid = {}
local GRID_SIZE = 500
local distanceCache = {}
local targetQueues = {}
local QUEUE_SIZE = 5

local function generateWorkAreaId()
    workAreaCounter = workAreaCounter + 1
    return "workarea_" .. workAreaCounter
end
local function getGridKey(pos)
    local x = math.floor(pos.x / GRID_SIZE)
    local y = math.floor(pos.y / GRID_SIZE)
    local z = math.floor(pos.z / GRID_SIZE)
    return string.format("%d,%d,%d", x, y, z)
end
local function getCachedDistance(pos1, pos2)
    if not pos1 or not pos2 then
        return math.huge
    end
    local key1 = string.format("%.1f,%.1f,%.1f", pos1.x, pos1.y, pos1.z)
    local key2 = string.format("%.1f,%.1f,%.1f", pos2.x, pos2.y, pos2.z)
    local cacheKey = key1 .. "|" .. key2
    if distanceCache[cacheKey] then
        return distanceCache[cacheKey]
    end
    local dist = distance2(pos1, pos2)
    if dist and dist >= 0 then
        distanceCache[cacheKey] = dist
    else
        dist = math.huge -- Invalid distance
    end
    local cacheSize = 0
    for _ in pairs(distanceCache) do
        cacheSize = cacheSize + 1
    end
    if cacheSize > 1000 then
        distanceCache = {} -- Clear cache if it gets too large
    end
    return dist
end
local function getNearbyGridCells(center, radius)
    local cells = {}
    local cellRadius = math.ceil(radius / GRID_SIZE)
    local centerKey = getGridKey(center)
    local centerX, centerY, centerZ = centerKey:match("([^,]+),([^,]+),([^,]+)")
    centerX, centerY, centerZ = tonumber(centerX), tonumber(centerY), tonumber(centerZ)
    for x = centerX - cellRadius, centerX + cellRadius do
        for y = centerY - cellRadius, centerY + cellRadius do
            for z = centerZ - cellRadius, centerZ + cellRadius do
                local key = string.format("%d,%d,%d", x, y, z)
                if spatialGrid[key] then
                    table.insert(cells, key)
                end
            end
        end
    end
    return cells
end
function SalvageWorkAreaManager.createWorkArea(squadId, initialTargetPos, initialTargetId)
    local workAreaId = generateWorkAreaId()
    local workArea = {
        id = workAreaId,
        center = initialTargetPos,
        radius = WORK_AREA_CONFIG.INITIAL_RADIUS,
        maxRadius = WORK_AREA_CONFIG.MAX_RADIUS,
        assignedSquad = squadId,
        targets = {initialTargetId},
        lastExpansion = 0,
        totalTargetsProcessed = 1
    }
    workAreas[workAreaId] = workArea
    squadAssignments[squadId] = workAreaId
    return workAreaId
end
function SalvageWorkAreaManager.getNextTargetInWorkArea(squadId, currentTargetPos, miningFilters, wreckageCache, validateWreckageResources)
    if not squadId or not currentTargetPos or not miningFilters then
        return nil
    end
    local bestTarget = nil
    local bestDistance = math.huge
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if valid(wreckageData.entity) and not wreckageData.assigned then
            local material = wreckageData.entity:getMineableMaterial()
            if material and miningFilters[material.value] == true then
                if validateWreckageResources(wreckageId) then
                    local distance = distance2(wreckageData.translationf, currentTargetPos)
                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = Uuid(wreckageId)
                    end
                end
            end
        end
    end
    return bestTarget
end
function SalvageWorkAreaManager.assignSquadToTarget(squadId, targetId, targetPos)
    local workAreaId = squadAssignments[squadId]
    if not workAreaId then
        workAreaId = SalvageWorkAreaManager.createWorkArea(squadId, targetPos, targetId)
    else
        local workArea = workAreas[workAreaId]
        if workArea then
            workArea.center = targetPos
        end
    end
    return workAreaId
end
function SalvageWorkAreaManager.removeSquadWorkArea(squadId)
    local workAreaId = squadAssignments[squadId]
    if workAreaId then
        workAreas[workAreaId] = nil
        squadAssignments[squadId] = nil
    end
end
function SalvageWorkAreaManager.getSquadWorkArea(squadId)
    local workAreaId = squadAssignments[squadId]
    if workAreaId then
        return workAreas[workAreaId]
    end
    return nil
end
function SalvageWorkAreaManager.getAllWorkAreas()
    return workAreas
end
function SalvageWorkAreaManager.cleanupOrphanedWorkAreas(activeSquadIds)
    local activeSquadSet = {}
    for _, squadId in ipairs(activeSquadIds) do
        activeSquadSet[squadId] = true
    end
    for squadId, workAreaId in pairs(squadAssignments) do
        if not activeSquadSet[squadId] then
            workAreas[workAreaId] = nil
            squadAssignments[squadId] = nil
        end
    end
end
function SalvageWorkAreaManager.updateWorkAreaStats()
    for workAreaId, workArea in pairs(workAreas) do
        workArea.lastExpansion = workArea.lastExpansion + 1
    end
end
function SalvageWorkAreaManager.getConfig()
    return WORK_AREA_CONFIG
end
function SalvageWorkAreaManager.setConfig(config)
    for key, value in pairs(config) do
        if WORK_AREA_CONFIG[key] then
            WORK_AREA_CONFIG[key] = value
        end
    end
end
function SalvageWorkAreaManager.updateStats()
    SalvageWorkAreaManager.updateWorkAreaStats()
end
function SalvageWorkAreaManager.updateSpatialGrid()
    spatialGrid = {}
    local allWreckages = UnifiedWreckageCache.getAllWreckages()
    for wreckageId, wreckageData in pairs(allWreckages) do
        if valid(wreckageData.entity) then
            local gridKey = getGridKey(wreckageData.translationf)
            if not spatialGrid[gridKey] then
                spatialGrid[gridKey] = {}
            end
            table.insert(spatialGrid[gridKey], wreckageId)
        end
    end
end
function SalvageWorkAreaManager.addWreckageToGrid(wreckageId, position)
    local gridKey = getGridKey(position)
    if not spatialGrid[gridKey] then
        spatialGrid[gridKey] = {}
    end
    table.insert(spatialGrid[gridKey], wreckageId)
end
function SalvageWorkAreaManager.removeWreckageFromGrid(wreckageId, position)
    local gridKey = getGridKey(position)
    if spatialGrid[gridKey] then
        for i, id in ipairs(spatialGrid[gridKey]) do
            if id == wreckageId then
                table.remove(spatialGrid[gridKey], i)
                break
            end
        end
        if #spatialGrid[gridKey] == 0 then
            spatialGrid[gridKey] = nil
        end
    end
end
function SalvageWorkAreaManager.buildTargetQueue(squadId, centerPos, miningFilters, validateWreckageResources)
    if not squadId or not centerPos or not miningFilters then
        return {}
    end
    local queue = {}
    local workAreaId = squadAssignments[squadId]
    local workArea = workAreaId and workAreas[workAreaId]
    local searchRadius = workArea and workArea.radius or WORK_AREA_CONFIG.INITIAL_RADIUS
    local targets = {}
    local nearbyCells = getNearbyGridCells(centerPos, searchRadius)
    for _, cellKey in ipairs(nearbyCells) do
        local cellWreckages = spatialGrid[cellKey] or {}
        for _, wreckageId in ipairs(cellWreckages) do
            local wreckageData = UnifiedWreckageCache.getWreckage(wreckageId)
            if wreckageData and valid(wreckageData.entity) and not wreckageData.assigned then
                local material = wreckageData.entity:getMineableMaterial()
                if material and miningFilters[material.value] == true then
                    if validateWreckageResources(wreckageId) then
                        local distance = getCachedDistance(wreckageData.translationf, centerPos)
                        local resourceValue = wreckageData.resourceAmount or 0
                        if resourceValue >= WORK_AREA_CONFIG.MIN_RESOURCE_THRESHOLD then
                            local score = (distance * WORK_AREA_CONFIG.DISTANCE_WEIGHT) - 
                                        (resourceValue * WORK_AREA_CONFIG.RESOURCE_WEIGHT)
                            table.insert(targets, {
                                id = Uuid(wreckageId),
                                score = score,
                                distance = distance,
                                resources = resourceValue
                            })
                        end
                    end
                end
            end
        end
    end
    table.sort(targets, function(a, b) return a.score < b.score end)
    for i = 1, math.min(QUEUE_SIZE, #targets) do
        table.insert(queue, targets[i].id)
    end
    targetQueues[squadId] = queue
    return queue
end
function SalvageWorkAreaManager.getNextTargetFromQueue(squadId)
    local queue = targetQueues[squadId]
    if not queue or #queue == 0 then
        return nil
    end
    local target = table.remove(queue, 1)
    return target
end
function SalvageWorkAreaManager.addTargetToQueue(squadId, targetId)
    local queue = targetQueues[squadId]
    if not queue then
        queue = {}
        targetQueues[squadId] = queue
    end
    for _, id in ipairs(queue) do
        if tostring(id) == tostring(targetId) then
            return false
        end
    end
    table.insert(queue, targetId)
    return true
end
function SalvageWorkAreaManager.clearTargetQueue(squadId)
    targetQueues[squadId] = {}
end
function SalvageWorkAreaManager.getStats()
    local stats = {
        totalWorkAreas = 0,
        totalSquads = 0,
        averageRadius = 0,
        totalTargetsProcessed = 0
    }
    local totalRadius = 0
    for _, workArea in pairs(workAreas) do
        stats.totalWorkAreas = stats.totalWorkAreas + 1
        stats.totalSquads = stats.totalSquads + 1
        totalRadius = totalRadius + workArea.radius
        stats.totalTargetsProcessed = stats.totalTargetsProcessed + workArea.totalTargetsProcessed
    end
    if stats.totalWorkAreas > 0 then
        stats.averageRadius = totalRadius / stats.totalWorkAreas
    end
    return stats
end
return SalvageWorkAreaManager
