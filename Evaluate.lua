--[[
Evaluate.lua

This script is used to evaluate how good an AI is on a track. It plays the AI for a
configurable number of runs, recording the finish time. It reports DNF if the AI fails to
finish the race and gets stuck.
]]--

--[[ BEGIN CONFIGURATION ]]--
local NUM_RUNS = 10
--[[ END CONFIGURATION ]]--

local util = require("util")
local play = loadfile("Play.lua")

local START_STATE_FILE = util.getTMPDir() .. '\\eval-start.state'
savestate.save(START_STATE_FILE)

client.unpause()
event.onexit(function()
  client.pause()
  savestate.load(START_STATE_FILE)
end)

print("Mode:", util.readMode(), "Course:", util.readCourse())

for i=1, 10 do
    -- Start from the beginning and play.
    savestate.load(START_STATE_FILE)
    play()

    if util.readProgress() >= 3 then
      print ("Run " .. i .. ":", util.readTimer())
    else
      print ("Run " .. i .. ":", "DNF")
    end
end
