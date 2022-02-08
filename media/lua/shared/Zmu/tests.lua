local Config = require("Zmu/Config")
local Logger = require("Zmu/Logger")
local Timer = require("Zmu/Timers")

local logger = Logger:new('ZMU', Logger.DEBUG)
local config = Config:new('ZMU', logger)
config:add("BoolTest", {type='boolean', default=true})
config:add("FloatTest", {type='float', min=0.1, default=0.6})
config:add("IntTest", {type='integer', min=0, max=100, default=50})

config:set("BoolTest", false)
config:set("FloatTest", false)
config:set("IntTest", 101)

config:save("testing.ini")
config:reset()
config:load("testing.ini")
