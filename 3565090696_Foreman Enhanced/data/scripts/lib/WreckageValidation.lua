local _wreckageValidationCacheValid = false
local _wreckageValidationCache = {}
local _wreckageValidationCacheTime = {}
local function invalidateWreckageValidationCache()
    _wreckageValidationCacheValid = false
    _wreckageValidationCache = {}
    _wreckageValidationCacheTime = {}
end
local function validateWreckageResources(wreckageIndex, wreckageCache)
    if _wreckageValidationCacheValid and _wreckageValidationCache[wreckageIndex] ~= nil then
        local now = os.clock()
        if not _wreckageValidationCacheTime[wreckageIndex] then 
            _wreckageValidationCacheTime[wreckageIndex] = now 
        end
        if (now - _wreckageValidationCacheTime[wreckageIndex]) < 2 then
            return _wreckageValidationCache[wreckageIndex]
        end
    end
    local wreckage = Entity(Uuid(wreckageIndex))
    if not valid(wreckage) then
        _wreckageValidationCache[wreckageIndex] = false
        return false
    end
    local amount = 0
    for _, j in pairs({wreckage:getMineableResources()}) do
        amount = amount + j
    end
    local isValid = amount >= 1
    _wreckageValidationCache[wreckageIndex] = isValid
    _wreckageValidationCacheTime[wreckageIndex] = os.clock()
    if isValid then
        UnifiedWreckageCache = include("UnifiedWreckageCache")
        local wreckageData = UnifiedWreckageCache.getWreckage(tostring(wreckageIndex))
        if wreckageData and wreckageData.resourceAmount and math.abs(wreckageData.resourceAmount - amount) > 50 then
            wreckageData.resourceAmount = amount
            wreckageData.lastSeen = 0 -- Force refresh
        end
    end
    return isValid
end
local function markCacheValid()
    _wreckageValidationCacheValid = true
end
return {
    invalidateWreckageValidationCache = invalidateWreckageValidationCache,
    validateWreckageResources = validateWreckageResources,
    markCacheValid = markCacheValid
}
