local UpdateManager = {}
function UpdateManager.getUpdateInterval()
    if onServer() then
        return 1
    else
        return 1.0  -- Optimized: Reduced from 0.1 to 1.0 for better performance
    end
end
return UpdateManager
