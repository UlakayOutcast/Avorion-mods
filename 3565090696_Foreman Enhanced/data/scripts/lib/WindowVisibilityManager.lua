local WindowVisibilityManager = {}
WindowManager = include("WindowManager")
function WindowVisibilityManager.show(window, WindowManager, shouldUpdateCallback)
    WindowManager.showWindow(window, shouldUpdateCallback)
end
function WindowVisibilityManager.hide(window, WindowManager, shouldUpdateCallback)
    WindowManager.hideWindow(window, shouldUpdateCallback)
end
return WindowVisibilityManager
