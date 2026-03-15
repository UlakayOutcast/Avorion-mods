local _asteroidValidationCache = {}
local _validationCacheValid = false
local _wreckageValidationCache = {}
local _wreckageValidationCacheValid = false
local function invalidateAsteroidValidationCache()
    _validationCacheValid = false
    _asteroidValidationCache = {}
end
fms = fms or {}
fms.invalidateAsteroidValidationCache = invalidateAsteroidValidationCache
fms._asteroidValidationCache = _asteroidValidationCache
fms._validationCacheValid = _validationCacheValid
fms._wreckageValidationCache = _wreckageValidationCache
fms._wreckageValidationCacheValid = _wreckageValidationCacheValid
