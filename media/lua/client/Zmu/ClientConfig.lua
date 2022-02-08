-- TODO: logging

local Config = require("Zmu/Config")
local sendClientCommand = sendClientCommand
local pairs = pairs

Config.requestConfig = function(ticks)
    if ticks and ticks > 0 then return end
    if isClient() then
        for _, config in pairs(Config.getAllConfigs()) do
            sendClientCommand(getPlayer(), config.module_name, 'requestConfig', nil)
        end
    end
    Events.OnTick.Remove(Config.requestSettings)
end


--[[- Triggered by the OnServerCommand Event.

@tparam string module
@tparam string command
@tparam variable args

]]
local onServerCommand = function(module, command, args)
    if not isClient() then return end
    if command ~= "updateConfig" then return end
    local config = Config.getAllConfigs()[module]
    if not config then return end
    config:applyTemp(args)
end

Events.OnTick.Add(Config.requestSettings)
Events.OnServerCommand.Add(onServerCommand)
