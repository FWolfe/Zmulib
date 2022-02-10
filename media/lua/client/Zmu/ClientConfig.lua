--[[- Client side code for syncing configuration settings from servers

]]
local Config = require("Zmu/Config")
local sendClientCommand = sendClientCommand
local pairs = pairs

Config.requestConfig = function(ticks)
    Events.OnTick.Remove(Config.requestSettings)
    if isClient() then
        for _, config in pairs(Config.getAllConfigs()) do
            config.Logger:debug("Requesting config settings from server")
            sendClientCommand(getPlayer(), config.module_name, 'requestConfig', nil)
        end
    end
end


--[[- Triggered by the OnServerCommand Event.

@tparam string module
@tparam string command
@tparam variable args

]]
local onServerCommand = function(module, command, args)
    if not isClient() then return end
    if command ~= "updateConfig" then return end
    local config = Config.getConfig(module)
    if not config then return end
    config.Logger:debug("Recieved config settings from server")
    config:applyServerSettings(args)
end

Events.OnTick.Add(Config.requestSettings)
Events.OnServerCommand.Add(onServerCommand)
