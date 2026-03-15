local SectorLeftManager = {}

-- Automation debugging flag - set to true to enable debugging output
local AUTOMATION_DEBUG_ENABLED = false

function SectorLeftManager.onSectorLeft(playerIndex, x, y, sectorChangeType, sectorScanned, window, hideCallback)
    if playerIndex == Player().index then
        sectorScanned = false
        if onClient() and AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Sector left, settings will be saved via server-side functions")
        end
        if window then
            hideCallback()
        end
    end
end
return SectorLeftManager
