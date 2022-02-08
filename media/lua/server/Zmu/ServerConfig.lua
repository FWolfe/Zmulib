--[[- Server side code for syncing configuration settings to clients

]]

if not isServer() then return end

local Config = require("Zmu/Config")
local sendServerCommand = sendServerCommand

local onClientCommand = function(module, command, player, args)
    if command ~= "requestConfig" then return end
    local config = Config.getAllConfigs()[module]
    if not config then return end
    config.Logger:debug("Sending config settings to player")
    sendServerCommand(player, config.module_name, 'updateSettings', config.Settings)
end

Events.OnClientCommand.Add(onClientCommand)
