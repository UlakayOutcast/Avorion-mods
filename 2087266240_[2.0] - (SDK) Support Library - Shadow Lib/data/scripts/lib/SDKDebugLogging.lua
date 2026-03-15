package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")
include("randomext")

local SDKDebugLogging = {}

--[[
    m = (Method Name) Name of method passing request
    tn = (Table Name) The name of the table we are about to print
    t  = (Table) The table we are going to print
    l  = (Log) 0 = no, 1 = Yes. Allowes Toggeling DebugLogging and Overriding 
        Settings for warnings and error logging.
]]
function ToConsoleTable(m, tn, t, l)
    l =l or 0
    for key, value in pairs(t) do
        LogLine(fn, "Printing " .. tn .. " - Key = " .. key .. " | Value = " .. value, l)
    end
end

--[[
    Simple Print() Wrapping Fucntion that allows more control.
    m = (Method Name) The name of the calling method.
    t = (Text) The text being printed.
    l = (Log) 0 = no, 1 = Yes. Allowes Toggeling DebugLogging and Overriding 
        Settings for warnings and error logging.
]]
function LogLine(m, t, l)
    l = l or 0 if l == 1 then print("[" .. m .. "] " .. t) end
end

--[[
    Simple Warning Log formatting function to make it easier to log issues.
    m = (Method Name) The name of the calling method.
    t = (Text) The text being printed.    
]]
function LogWarning(m, t)
    LogLine(m, "(Warning) Something Went Wrong. " .. t, 1)
    LogLine(m, "Please Contact The Developer. Discord: Shadow Doctor K#2203", 1)
end

return SDKDebugLogging
