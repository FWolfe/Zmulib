--[[- Configuration and settings functions.

Provides configurations and settings for mods, with .ini file support, data validation and 
client/server syncing.


```lua
local Config = require("Zmu/Config")

-- create a new Config instance with the name "ZMU"
local config = Config:new('ZMU')

config:add("BoolTest", {type='boolean', default=true})
config:add("FloatTest", {type='float', min=0.1, default=0.6})
config:add("IntTest", {type='integer', min=0, max=100, default=50})

config:set("BoolTest", false)

-- attempt to set these to bad values:
config:set("FloatTest", false) -- throws a error (bool false is not a float). sets to default 0.6
config:set("IntTest", 101) -- throws a error (101 > max value 100) sets to 100

-- save the current settings. note FloatTest is not saved since its still at its default value of 0.6
-- only custom (changed) values are saved.
config:save("testing.ini")

-- reset to defaults
config:reset()

-- load our saved values
config:load("testing.ini")
```

Logging output of Config instances can be controlled by manually supplying a Logger instance:

```lua
local Config = require("Zmu/Config")
local Logger = require("Zmu/Logger")

local logger = Logger:new('ZMU', Logger.DEBUG)
local config = Config:new('ZMU', logger)
```

If no Logger is specified, one is created (or reused) with the same name as the config object. For example 
the following declaration is the same as above as the Logger named "ZMU" is reused.

```lua
local logger = Logger:new('ZMU', Logger.DEBUG)
local config = Config:new('ZMU')
```


@module Config
@author Fenris_Wolf
@release 1.00
@copyright 2019

]]

local pairs = pairs
local setmetatable = setmetatable
local math = math
local type = type
local tostring = tostring
local tonumber = tonumber
local string = string

local getFileReader = getFileReader
local getFileWriter = getFileWriter

local Logger = require("Zmu/Logger")
local Config = {}
local meta = { __index = Config }

local ConfigTable = {}
local AcceptedTypes = {
    "integer", "float", "boolean", "string"
}

function Config:new(module_name, logger)
    local module_name = module_name or "Config"
    local name = module_name -- for unique generation
    logger = logger or Logger:new(module_name) -- use supplied name to fetch logger

    -- generate a unique name (if it isnt already)
    if ConfigTable[name] then
        local c = 1
        repeat
            name = module_name .. tostring(c)
            c = 1+c
        until ConfigTable[name] == nil
    end

    local config = setmetatable({
        name = name,
        Logger = logger,
        Options = {
            LogLevel = {type='integer', min=0, max=5, default=logger.level}
        },
        Settings = {
            LogLevel = logger.level,
        }
    }, meta)
    ConfigTable[name] = config
    return config
end

local contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end
--[[- adds a new configuration setting with defaults and value limits.

@tparam string key
@tparam table data

]]
function Config:add(key, data)
    -- TODO: validate data key names (error checking)
    self.Logger:verbose("Adding config option " .. key)
    if self.Options[key] then
        self.Logger:error("Config option ".. key .. " already exists")
        return
    end
    if not data.type then
        self.Logger:error("Config option ".. key .. " is missing data type")
        return
    end
    if not contains(AcceptedKeys, data.type) then
        self.Logger:error("Config option ".. key .. " is invalid data type "..tostring(data.type))
        return
    end 
    self.Options[key] = data 
    self.Settings[key] = data.default
end

--[[- gets the configuration option table. 

@treturn table

]]
function Config:getOptionsTable()
    return self.Options
end

--[[- gets the configuration settings table. 

@treturn table

]]
function Config:getSettingsTable()
    return self.Settings
end

--[[- gets a configuration option. 

@tparam string key

@treturn nil|table

]]
function Config:option(key)
    return self.Options[key]
end

--[[- resets all configuration options to default. 

This will trigger the "ConfigReset" event

]]
function Config:reset()
    self.Logger:debug("Resetting config options to default values")
    for key, data in pairs(self.Options) do
        self.Settings[key] = data.default
    end
    self.Logger.level = self.Settings.LogLevel -- keep our logger in sync
    triggerEvent("OnConfigReset", self)
end


--[[- changes a configuration option. 

This will trigger the "OnConfigChange"

@tparam string key
@tparam string|number|boolean value

@treturn boolean true if changes were applied

]]
function Config:set(key, value) 
    if not self.Options[key] then 
        self.Logger:warn("Attempting set unknown config key " .. key .. " to " .. tostring(value))
        return nil 
    end
    local current = self.Settings[key]
    self.Logger:verbose("Attempting set config " .. key .. " to " .. tostring(value))

    value = self:validate(key, value)
    if current == value then --or EventSystem.triggerHalt("ConfigChange", key, current, value) then 
        self.Logger:verbose("Config change key cancelled " .. key .. " to " .. tostring(value))
        return false 
    end
    self.Settings[key] = value
    self.Logger.level = self.Settings.LogLevel -- keep our logger in sync
    self.Logger:debug("Config key " .. key .. " set to " .. tostring(value))
    triggerEvent('OnConfigChange', self, key, value)
    return true
end


--[[- gets the current value for a configuration option. 

@tparam string key

@treturn nil|string|number|boolean

]]
function Config:get(key)
    return self.Settings[key]
end


--[[- gets the default value for a configuration option. 

@tparam string key

@treturn nil|string|number|boolean

]]
function Config:default(key) 
    if not self.Options[key] then return nil end
    return self.Options[key].default
end


--[[- checks if a value is valid for a configuration option, and returns a valid version.
Called automatically with `Config:set(key, value)`

@tparam string key
@tparam string|number|boolean value

@treturn nil|string|number|boolean

]]
function Config:validate(key, value) 
    local options = self.Options[key]
    if not options then
        self.Logger:error("Attempted to validate non-existant config option " .. key) 
        return nil 
    end
    local validType = options.type
    self.Logger:verbose("Validating config key "..key)

    if validType == 'integer' or validType == 'float' then validType = 'number' end
    if type(value) ~= validType then -- wrong type
        self.Logger:error("Config " .. key .. " is invalid type (value "..tostring(value).." should be type "..options.type.."). Setting to default "..tostring(options.default))
        value = options.default
    end
    
    if options.type == 'integer' and value ~= math.floor(value) then
        self.Logger:error("Config " .. key .. " is invalid type (value "..tostring(value).." should be integer not float). Setting to default "..tostring(math.floor(value)))
        value = math.floor(value)
    end
    if validType == 'number' then
        if (options.min and value < options.min) or (options.max and value > options.max) then
            local clamp = math.min(math.max(value, options.min), options.max)
            self.Logger:error("Config " .. key .. " is invalid range (value "..tostring(value).." should be between min:"..(options.min or '')..", max:" ..(options.max or '').."). Setting to "..tostring(clamp))
            value = clamp
        end
    end
    return value
end


function Config:load(filename)
    self.Logger:debug("Loading config file " .. filename)

    local file = getFileReader(filename, true)
    if not file then return end
    for key, value in pairs(self:getOptionsTable()) do
        value.wasLoaded = nil -- set the wasLoaded flag to nil
    end
    while true do repeat
        local line = file:readLine()
        if line == nil then
            file:close()
            return
        end
        line = string.gsub(line, "^ +(.+) +$", "%1", 1)
        if line == "" or string.sub(line, 1, 1) == ";" then break end
        
        for key, value in string.gmatch(line, "(%w+) *= *(.+)") do
            local option = self:option(key)
            if not option then
                self.Logger:warn("Config: Invalid setting in "..filename.." ("..line..")")
                break
            end
            if option.type == "boolean" and value == string.lower("true") then
                value = true
            elseif option.type == "boolean" and value == string.lower("false") then
                value = false
            elseif option.type == "integer" or option.type == "float" then
                value = tonumber(value)
            end
            option.wasLoaded = true -- option was loaded from the config, so flag it for saving later
            self:set(key, value)
        end
    until true end
    triggerEvent("OnConfigLoaded", self, filename)
end


function Config:save(filename)
    if isClient() then return end -- dont overwrite a clients file with the servers settings
    self.Logger:debug("Saving config file ".. filename)
    local file = getFileWriter(filename, true, false)
    if not file then
        self.Logger:error("Failed to write config file Lua/" .. filename)
        return
    end
    for key, value in pairs(self:getSettingsTable()) do
        local option = self:option(key)
        if option and (option.wasLoaded or value ~= option.default) then
            file:write(key .. " = ".. tostring(value) .. "\r\n")
        end
    end
    file:close()

    triggerEvent("OnConfigSaved", self, filename)
end


-- with mods being enabled "per save" these functions are probably redundant now
function Config:applyTemp(settings_data)
    self.Logger:debug("Applying temporary config settings")
    if not self._PreviousSettings then
        self._PreviousSettings = {}
        for key, value in pairs(self:getSettingsTable()) do self._PreviousSettings[key] = value end
    end

    for key, value in pairs(args) do
        self:set(key, value)
    end
end

function Config:removeTemp()
    self.Logger:debug("Removing temporary config settings")
    if self._PreviousSettings then
        for key, value in pairs(self._PreviousSettings) do self:set(key, value) end
        self._PreviousSettings = nil
    end
end


-- static method. not instanced
function Config.getAllConfigs()
    return ConfigTable
end


LuaEventManager.AddEvent("OnConfigChange")
LuaEventManager.AddEvent("OnConfigLoaded")
LuaEventManager.AddEvent("OnConfigSaved")
LuaEventManager.AddEvent("OnConfigReset")

return Config
