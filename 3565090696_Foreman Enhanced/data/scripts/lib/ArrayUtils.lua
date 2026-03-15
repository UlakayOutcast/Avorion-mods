local ArrayUtils = {}

function ArrayUtils.removeFromArray(arrayTable, value)
    for idx, v in ipairs(arrayTable) do
        if v == value then
            table.remove(arrayTable, idx)
            return true
        end
    end
    return false
end

return ArrayUtils
