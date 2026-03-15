local WindowManager = {}
local clientWindowLastPos = nil
local serverSavedWindowPos = nil

function WindowManager.saveWindowPos_server(position)
    serverSavedWindowPos = position
end

function WindowManager.loadWindowPos_client()
    if onClient() then
        invokeServerFunction("sendWindowPos_server")
    end
end

function WindowManager.sendWindowPos_server(callingPlayer)
    local player = nil
    -- CRITICAL FIX: Don't fallback to random player
    if callingPlayer == nil then
        print("Foreman: ERROR - WindowManager function called without callingPlayer")
        return
    end
    
    player = Player(callingPlayer)
    if not player then
        print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
        return
    end
    if player then
        invokeClientFunction(player, "setWindowPos_client", serverSavedWindowPos)
    end
end
function WindowManager.setWindowPos_client(position, window)
    if window and position then
        local res = getResolution()
        if position.x < 0 or position.x > res.x or position.y < 0 or position.y > res.y then
            position = vec2(res.x * 0.65, res.y * 0.75)
        end
        window.position = position
        clientWindowLastPos = position
    end
end
function WindowManager.getClientWindowLastPos()
    return clientWindowLastPos
end
function WindowManager.setClientWindowLastPos(position)
    clientWindowLastPos = position
end
function WindowManager.getServerSavedWindowPos()
    return serverSavedWindowPos
end
function WindowManager.setServerSavedWindowPos(position)
    serverSavedWindowPos = position
end
function WindowManager.expandWindowForAutomation(window, automationVisible)
    if window and not automationVisible then
        local currentPos = window.position
        local currentSize = window.size
        window.size = vec2(currentSize.x + 300, currentSize.y)
        window.position = vec2(currentPos.x, currentPos.y)
    end
end
function WindowManager.contractWindowFromAutomation(window, automationVisible)
    if window and automationVisible then
        local currentPos = window.position
        local currentSize = window.size
        window.size = vec2(currentSize.x - 300, currentSize.y)
        window.position = vec2(currentPos.x, currentPos.y)
    end
end
function WindowManager.showWindow(window, shouldUpdateCallback)
    if window then
        window:show()
    end
    if shouldUpdateCallback then
        shouldUpdateCallback(true)
    end
end
function WindowManager.hideWindow(window, shouldUpdateCallback)
    if shouldUpdateCallback then
        shouldUpdateCallback(false)
    end
    if window then
        window:hide()
    end
end
function WindowManager.toggleMinimize(window, minimized, unminimizedHeight, uiContainer)
    if window then
        if minimized then
            minimized = false
            window.height = unminimizedHeight
            window.position = vec2(window.position.x, math.max(0, window.position.y - 300))  -- Updated from 260 to 300
            uiContainer:show()
        else
            minimized = true
            window.height = 0
            local res = getResolution()
            window.position = vec2(window.position.x, math.min(res.y - 50, window.position.y + 300))  -- Updated from 260 to 300
            uiContainer:hide()
        end
    end
    return minimized
end
return WindowManager
