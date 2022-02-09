
# Zmulib - Zomboid Mod Utilities Library

A collection of modules and functions to assist in creating mods for Project Zomboid

## Modules:  

Timers.lua - Timer module that allows for code to be run 1 minute (game time) intervals
with a specified number of repeats (or indefinitly)  

Config.lua - Provides configurations and settings for mods, with .ini file support, data 
validation and client/server syncing.  

Logger.lua - Multi-instance logger with various levels (error, warn, info, debug and verbose).
Each Logger instance has its own level, and by default prints to the console but specific 
callback functions can be provided instead.
