--[[- Generic Logger module

Provides various logging functionality with various levels (error, warn, info, debug and verbose).
Each Logger instance has its own level, and by default prints to the console but specific callback functions
can be provided instead.

Each line is formatted as "NAME LEVEL: TEXT"

```lua
local Logger = require("Zmu/Logger")
local log = Logger:new("MyLogger", Logger.INFO)

log.info("this is a info message")
log.warn("this is a warning")
log.error("this is a error message")
log.debug("this message wont get printed, since we specified Logger.INFO")

-- change the level
log.level = Logger.DEBUG
log.debug("now we can print debug messages!")
```

to fetch a existing Logger instance from another file (without poluting globals) we can use:

```lua
local Logger = require("Zmu/Logger")
local log = Logger:getLogger("MyLogger")
```


@module Logger
@author Fenris_Wolf
@release 1.00
@copyright 2019

]]

local print = print
local string = string
local setmetatable = setmetatable

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


function Logger:new(module_name, level, callback)
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
        _callback = callback or print
        }, meta)
    LoggerTable[module_name] = logger
    return logger
end

--[[- Basic logging function.

By default prints a message to stdout if Logger.level is equal or less then the level arguement.

@tparam int level logging level constant
@tparam string text text message to log.

@usage Logger.log(ORGM.WARN, "this is a warning log message")

]]
function Logger:log(level, text)
    if not level or level > self.level then return end
    self._callback(string.format("%s %s: %s", self.module_name, (LogLevelStrings[level] or ""), text))
end

function Logger:verbose(text)
    self:log(Logger.VERBOSE, text)
end

function Logger:debug(text)
    self:log(Logger.DEBUG, text)
end

function Logger:info(text)
    self:log(Logger.INFO, text)
end

function Logger:warn(text)
    self:log(Logger.WARN, text)
end

function Logger:error(text)
    self:log(Logger.ERROR, text)
end

function Logger:getLogger(module_name)
    module_name = module_name or "Logger"
    return LoggerTable[module_name]
end

-- create a new default logger
Logger:new() 

return Logger
