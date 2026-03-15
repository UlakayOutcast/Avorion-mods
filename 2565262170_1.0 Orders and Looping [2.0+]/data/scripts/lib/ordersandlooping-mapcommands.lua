package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/player/background/?.lua"

math.randomseed(os.time())

local Azimuth = include("azimuthlib-basic")
local azimuthLoaded = Azimuth ~= nil
local CommandType = include ("simulation/commandtype")

local OALMapCommands = {}

function OALMapCommands.initialize()
    OALMapCommands.commands = {}
    OALMapCommands.commandsOrder = {}

    -- Load configuration using Azimuth
    OALMapCommands._azimuthOptions = {
        ["showMissions"] = {true, comment = "Display Avorion 2.0 Missions"},
        ["missionsConfig"] = {
            {
                [CommandType.Travel]        = true,
                [CommandType.Scout]         = true,
                [CommandType.Mine]          = true,
                [CommandType.Salvage]       = true,
                [CommandType.Refine]        = true,
                [CommandType.Procure]       = true,
                [CommandType.Sell]          = true,
                [CommandType.Trade]         = true,
                [CommandType.Supply]        = true,
                [CommandType.Expedition]    = true,
                [CommandType.Maintenance]   = true,
                [CommandType.Escort]        = true
            },
            comment = "Avorion 2.0 Mission Configs (showMissions must be enabled)"
        },
        [string.format("missionsConfig.%s", CommandType.Travel)]    = {true, comment = "Travel"},
        [string.format("missionsConfig.%s", CommandType.Scout)]     = {true, comment = "Scout"},
        [string.format("missionsConfig.%s", CommandType.Mine)]      = {true, comment = "Mine"},
        [string.format("missionsConfig.%s", CommandType.Salvage)]   = {true, comment = "Salvage"},
        [string.format("missionsConfig.%s", CommandType.Refine)]    = {true, comment = "Refine"},
        [string.format("missionsConfig.%s", CommandType.Procure)]   = {true, comment = "Procure"},
        [string.format("missionsConfig.%s", CommandType.Sell)]      = {true, comment = "Sell"},
        [string.format("missionsConfig.%s", CommandType.Trade)]     = {true, comment = "Trade"},
        [string.format("missionsConfig.%s", CommandType.Supply)]    = {true, comment = "Supply"},
        [string.format("missionsConfig.%s", CommandType.Expedition)]= {true, comment = "Expedition"},
        [string.format("missionsConfig.%s", CommandType.Maintenance)]   = {true, comment = "Maintenance"},
        [string.format("missionsConfig.%s", CommandType.Escort)]    = {true, comment = "Escort"},
        ["ordersConfig"] = {{}, comment = "Avorion Order Configs" }
    }
    OALMapCommands._readConfig()

    -- Save if modified or not found
    -- if err == 0 or err == 1 then
    OALMapCommands._saveConfig() -- force save every time for now
    -- end

    -- Keep copies of overridden base functions
    OALMapCommands._initUI = MapCommands.initUI
    OALMapCommands._updateOrderButtons = MapCommands.updateOrderButtons
end

-- Checks if a command is enabled via the OrdersAndLooping config file
function OALMapCommands.commandEnabled(commandType)
    if OALMapCommands.config["missionsConfig"][commandType] ~= nil then
        return OALMapCommands.config["showMissions"] and OALMapCommands.config["missionsConfig"][commandType]
    elseif OALMapCommands.config["ordersConfig"][commandType] ~= nil then
        return OALMapCommands.config["ordersConfig"][commandType]["enabled"]
    else
        return true
    end
end

-- Adds a modded command to the OrdersAndLooping commands table to be passed to MapCommands later
function OALMapCommands.addCommand(typeName, tooltip, icon, callback, stationAllowed)
    -- Generate unique id for never before seen orders and save
    if not OALMapCommands.config["ordersConfig"][typeName] then
        OALMapCommands.config["ordersConfig"][typeName] = {
            enabled = true,
            uuid = OALMapCommands._generateUUID()
        }
        OALMapCommands._saveConfig()
    end

    -- Only insert new commands, override duplicates
    if not OALMapCommands.commands[typeName] then
        OALMapCommands.commandsOrder[#OALMapCommands.commandsOrder+1] = typeName
    end
    OALMapCommands.commands[typeName] = {
        type = OALMapCommands.config["ordersConfig"][typeName].uuid,
        tooltip = tooltip,
        icon = icon,
        callback = callback,
        stationAllowed = stationAllowed
    }
end

-- Inserts modded orders into the MapCommands orders table
function OALMapCommands.applyCommands(orderButtonType, orders)
    for _, typeName in pairs(OALMapCommands.commandsOrder) do
        local command = OALMapCommands.commands[typeName]
        orderButtonType[typeName] = command.type

        if OALMapCommands.commandEnabled(typeName) then
            table.insert(orders, command)
        end
    end
end

-- Apply default configuration file
function OALMapCommands._setDefaultConfig()
    OALMapCommands.config = {
        ["showMissions"] = true,
        ["missionsConfig"] = {
            [CommandType.Travel]        = true,
            [CommandType.Scout]         = true,
            [CommandType.Mine]          = true,
            [CommandType.Salvage]       = true,
            [CommandType.Refine]        = true,
            [CommandType.Procure]       = true,
            [CommandType.Sell]          = true,
            [CommandType.Trade]         = true,
            [CommandType.Supply]        = true,
            [CommandType.Expedition]    = true,
            [CommandType.Maintenance]   = true,
            [CommandType.Escort]        = true,
        },
        ["ordersConfig"] = {}
    }
end

-- Read and set config file using Azimuth (using default if Azimuth dependency unmet), returning error (if any)
function OALMapCommands._readConfig()
    local err = nil

    -- Skip if already set up
    if OALMapCommands.config ~= nil then
        return
    end

    if azimuthLoaded then
        OALMapCommands.config, err = Azimuth.loadConfig("1.0 Orders and Looping", OALMapCommands._azimuthOptions, false, true)
    else
        -- Use default config if Azimuth dependency not met
        OALMapCommands._setDefaultConfig()
    end

    return err
end

-- Save config file using Azimuth, skip if missing
function OALMapCommands._saveConfig()
    if azimuthLoaded then
        Azimuth.saveConfig("1.0 Orders and Looping", OALMapCommands.config, OALMapCommands._azimuthOptions, false, true, false)
    end
end

-- Helper to generate UUID used for OrderButtonType
function OALMapCommands._generateUUID()
    return string.gsub('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx', '[xy]',
        function (c)
            local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format('%x', v)
        end
    )
end

return OALMapCommands