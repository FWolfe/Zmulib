--[[- Generic Logger module

Provides various logging functionality with various levels (error, warn, info, debug and verbose).
Each Logger instance has its own level, and by default prints to the console but specific callback functions
can be provided instead.
As well as printing to console (or custom defined function) Logger can output to a log file (located in pz's 
cache log directory) with timestamps in zomboid's standard format. Each Logger instance can use differnt 
log files, or share the same file (this differnt mods could be sharing one log file, each outputting different 
levels, one debug, one errors only etc)

By default each line is formatted as "NAME LEVEL: TEXT"

```lua
local Logger = require("Zmu/Logger")
local log = Logger:new("MyLogger", Logger.INFO)

log:error("this is a error message")
log:warn("this is a warning")
log:info("this is a info message")
log:debug("this message wont get printed, since we specified Logger.INFO")

-- change the level
log.level = Logger.DEBUG
log:debug("now we can print debug messages!")
```

to fetch a existing Logger instance from another file (without poluting globals) we can use:

```lua
local Logger = require("Zmu/Logger")
local log = Logger:getLogger("MyLogger")
```

Logger supports automaic formatting of output when multiple arguments are given. (see the documentation
for lua's string.format)
```lua
log:info("This number is rounded to %s decimal places: %.3f", "three", 1.2345678)
```

@module Logger
@author Fenris_Wolf
@release 1.00
@copyright 2019

]]

local setmetatable = setmetatable
local string = string
local format = string.format
local print = print

local ZLogger = ZLogger

local Logger = {}
Logger.NONE = 0
Logger.ERROR = 1
Logger.WARN = 2
Logger.INFO = 3
Logger.DEBUG = 4
Logger.VERBOSE = 5

local meta = {__index = Logger}
local LoggerTable = { }
local LogLevelStrings = {
    [0] = "NONE",
    [1] = "ERROR",
    [2] = "WARN",
    [3] = "INFO",
    [4] = "DEBUG",
    [5] = "VERBOSE"
}

--[[- Creates a new Logger instance

@tparam string module_name A unique name to assign this Logger instance, which will get prefixed
    to all output messages. If the name is already in use then the pre-existing Logger instance
    will be returned. 

@tparam int level Any messages with a equal or lower level will be output. Should be one of the constants:
    Logger.NONE, Logger.ERROR, Logger.WARN, Logger.INFO, Logger.DEBUG, Logger.VERBOSE

@tparam nil|boolean|ZLogger zlogger If true then outputs to a log file (with timestamps) in pz's cache
    logs directory with the name format: DATE_TIME_MODULENAME.txt. If a instance of ZLogger is supplied
    instead of a boolean value, it will use that instead of creating a new log (thus multiple Logger 
    instances can output to a single file)

@tparam nil|func callback A function to call when outputting messages. By default print() is used.

@treturn Logger

]]
function Logger:new(module_name, level, zlogger, callback)
    module_name = module_name or "Logger"
    local logger = LoggerTable[module_name]
    if logger then -- logger exists, update level and callback
        logger.level = level or logger.level
        logger._callback = callback or logger._callback
        return logger
    end
    
    -- create a new logger
    logger = setmetatable({
        module_name = module_name,
        level = level or 2,
        _callback = callback or print,
        format = "%s %s: %s"
        }, meta)

    LoggerTable[module_name] = logger
    
    -- add a log file if requested (also check that ZLogger actually exists - for using outside pz)
    if zlogger and ZLogger then
        if not instanceof(zlogger, "ZLogger") then
            zlogger = ZLogger.new(module_name, false)
        end 
        logger.ZLogger = zlogger
    end
    return logger
end

--[[- Basic logging function.

By default prints a message to stdout if Logger.level is equal or less then the level arguement.
This method supports multiple argument styles for the text message. Single string arg text logs
a basic string. Using multiple args they get passed to `string.format`

Note: Use of the wrapper methods (`logger:warn`, `Logger:debug` etc) should be preferred.

@tparam int level logging level constant
@tparam string text text message to log.

@usage logger:log(Logger.WARN, "this is a warning log message")

]]
function Logger:log(level, text, ...)
    if not level or level > self.level then return end
    if ... then text = format(text, ...) end
    text = format(self.format, self.module_name, (LogLevelStrings[level] or ""), text)
    if self._callback then self._callback(text) end
    if self.ZLogger then self.ZLogger:write(text) end
end

function Logger:verbose(...)
    self:log(Logger.VERBOSE, ...)
end

function Logger:debug(...)
    self:log(Logger.DEBUG, ...)
end

function Logger:info(...)
    self:log(Logger.INFO, ...)
end

function Logger:warn(...)
    self:log(Logger.WARN, ...)
end

function Logger:error(...)
    self:log(Logger.ERROR, ...)
end

function Logger:getLogger(module_name)
    module_name = module_name or "Logger"
    return LoggerTable[module_name]
end

-- create a new default logger
Logger:new() 

return Logger
