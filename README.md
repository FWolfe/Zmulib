
# Zmulib - Zomboid Mod Utilities Library

A collection of modules and functions to assist in creating mods for Project Zomboid

## Modules Overview:  

#### Timers.lua  
Timer module that allows for code to be run 1 minute (game time) intervals
with a specified number of repeats (or indefinitly)  

```lua
local Timers = require("Zmu/Timers")

local myCallback = function(self, player, text)
    player:Say(text .. tostring(self.repeats))
end

-- add a new timer on entering the game, triggered every 2 minutes, 10 times
Events.OnGameStart.Add(function()
    local timer = Timers.add("myTimer", 2, 10, myCallback, getPlayer(), "this is my timer. repeats left: ")
end)
```

```lua
local Timers = require("Zmu/Timers")
-- add a new timer on entering the game, triggered every minute forever until the player goes outside
Events.OnGameStart.Add(function()
    local timer = Timers.add("myTimer", 1, true, nil, getPlayer())
    
    function timer:callback(player)
        local square = player:getCurrentSquare()
        if square and square:isOutside() then
            player:Say("outside!")
            Timers.remove(self)
        else
            player:Say("indoors!")
        end
    end
end)
```

#### Config.lua  
Provides configurations and settings for mods, with .ini file support, data 
validation and client/server syncing.  

#### Logger.lua  
Multi-instance logger with various levels (error, warn, info, debug and verbose).
Each Logger instance has its own level, and by default prints to the console but 
specific callback functions can be provided instead. Can also timestamp and log 
entries to a file.

A full example of multiple Logger instances on a shared output file and custom callback:
```lua
local Logger = require('Zmu/Logger')

-- create a ZLogger instance to log to a shared log file.
local zlogger = ZLogger.new("MyLog", false)

-- now create 3 different Logger instances with different output levels and link
-- them all to the same log file. Normally these Logger instance would be in
-- different mods instead of one place.
local log1 = Logger:new("Mod1", Logger.INFO, zlogger)
local log2 = Logger:new("Mod2", Logger.ERROR, zlogger)
local log3 = Logger:new("Mod3", Logger.DEBUG, zlogger, fuction(text)
    -- have the player say the message for log3, instead of printing to console
    -- note this still goes to our custom log file.
    local player = getPlayer()
    if player then player:Say(text) end
end)

-- log some various messages
log1:info("log1 shows info messages, warnings and errors")
log1:warn("this is a warning message")
log2:warn("log2 doesnt print warnings") -- wont print or log to file
log2:error("log2 only prints error messages")
log3:debug("can even format %s like %s", "messages", "this")
log3:info("it uses string.format syntax like %.2f and %04d", 123.4567, 55)
```
