--[[- Timer module for project zomboid

This modules allows for code to be run 1 minute (game time) intervals
with a specified number of repeats (or indefinitly)

```lua
local Timers = require("Zmu/Timers")

-- callback function for when the timer executes
local myCallback = function(self, player, text)
    player:Say(text .. tostring(self.repeats))
end

-- add a new timer on entering the game, triggered every 2 minutes, 10 times
Events.OnGameStart.Add(function()
    Timers.add("myTimer", 2, 10, myCallback, getPlayer(), "this is my timer. repeats left: ")

    -- another format:
    -- add a new timer on entering the game, triggered every minute forever until the 
    -- player goes outside
    local timer = Timers.add("myTimer", 1, true, nil, getPlayer())
    
    function timer:callback(player)
        local square = player:getCurrentSquare()
        if square and square:isOutside() then
            player:Say("Sure is a nice day outside!")
            self:delete()
        else
            player:Say("This house is boring.")
        end
    end
end)
```

@module Timers
@author Fenris_Wolf
@release 1.00
@copyright 2019

]]

local type = type
local pairs = pairs
local unpack = unpack
local math = math
local setmetatable = setmetatable
local ZombRand = ZombRand
local getGameTime = getGameTime

local lastMinute = nil -- last game minute

local ActiveTimers = {} -- list of activated timers
local Timer = {}
local meta = { __index = Timer }

--[[- Generates a new timer and adds it to the list of active timers

Note timers are given a non-unique identifier by the caller, and a unique id is generated automatically.
this allows timers to be grouped by id for example with the Timers.remove_all(id) function) or individually selected 
with the Timers.remove(id) function.
Timers.Timer:new() can also be shortcut using the Timers.add() function

@tparam id string identifier needs not be unique.
@tparam delay int number of minutes to delay start (or repeat increment)
@tparam repeats int|bool number of times to repeat unless 0 or false. -1 or true to repeat forever 
@tparam callback function called when the timer executes (note the first argument to this function should be self: the timer)
@param ... all additional arguments will be passed to the callback function

@treturn Timer the new Timer instance

]]
function Timer:new(id, delay, repeats, callback, ...)
    local t = setmetatable({
        id = id,
        delay = math.floor(delay),
        repeats = repeats,
        callback = callback,
        next = getGameTime():getWorldAgeHours() + (delay/60),
        args = {...},
    }, meta)

    repeat 
        t.uid = ZombRand(100000) .."-".. t.next
    until ActiveTimers[t.uid] == nil

    ActiveTimers[t.uid] = t
    return t
end


--[[- Deletes the timer from the queue

]]
function Timer:delete()
    ActiveTimers[self.uid] = nil
end


--[[- Triggers the timers callback function

@tparam current_time double|nil the current world time (leave nil if manually calling)
 
]]
function Timer:trigger(current_time)
    if not self.repeats or self.repeats == 0 then
        ActiveTimers[uid] = nil
        
    elseif type(self.repeats) == "number" then
        self.repeats = self.repeats - 1
    end
    if not current_time then
        current_time = getGameTime():getWorldAgeHours()
    end
    self.next = current_time + (self.delay/60)
    self:callback(unpack(self.args))
end


--[[- Do nothing placeholder callback function incase callback is nil

]]
function Timer:callback(...)

end


--[[- checks the timers in the queue and triggers any pending callbacks

This function is called automatically OnTick

]]
local check = function()
    local minute = getGameTime():getMinutes()
    if minute == lastMinute then return end
    lastMinute = minute

    local current_time = getGameTime():getWorldAgeHours()
    for uid, timer in pairs(ActiveTimers) do
        if timer.next <= current_time then
            timer:trigger(current_time)
        end
    end
end


--[[- shortcut to Timer:new()

see Timer:new() for arguments and usage.

]]
local add = function(...)
    return Timer:new(...)
end


--[[- removes the timer with the matching unique id

@tparam uid string|Timer If a Timer instance is passed as the arg, the timer will remove itself

]]
local remove = function(uid)
    ActiveTimers[type(uid) == "table" and uid.uid or uid] = nil
end


--[[- removes all timers with matching id

@tparam id string|Timer If a Timer instance is passed as the arg, the timer's id will be used to match

]]
local remove_all = function(id)
    if type(id) == "table" then
        id = id.id
    end
    for uid, timer in pairs(AcitiveTimers) do
        if timer.id == id then
            ActiveTimers[uid] = nil
        end
    end
end


--[[- returns the timer with the matching unique id

@tparam uid string the unique id to match

@treturn Timer

]]
local get = function(uid)
    return ActiveTimers[uid]
end


--[[- returns all timers with matching id

@tparam id string the id to match

@treturn table a table of key (uid) value (Timer) pairs

]]
local get_all = function(id)
    if type(id) == "table" then
        id = id.id
    end
    local results = {}
    for uid, timer in pairs(AcitiveTimers) do
        if timer.id == id then
            results[uid] = timer
        end
    end
    return results
end


Events.OnTick.Add(check)
return {
    Timer = Timer,
    add = add,
    remove = remove,
    remove_all = remove_all,
    get = get,
    get_all = get_all,
    check = check,
}
