--[[
Demo.lua

This script plays selected tracks forever in a loop, for purposes of demoing the AI. ]]--

--[[ BEGIN CONFIGURATION ]]--
RACE_END_FRAMES = 700 -- The number of frames to show the time cards at the end of a race.
TRACKS = {'states/TT/LR.state', 'states/GP/MMF.state', 'states/TT/CM.state'}
--[[ END CONFIGURATION ]]--

local util = require("util")
local play = loadfile("Play.lua")

client.unpause()
event.onexit(function()
  client.pause()
end)

local state = 1
while true do
    -- Start from the beginning and play.
    savestate.load(TRACKS[state])
    print("Mode:", util.readMode(), "Course:", util.readCourse())

    play()

    -- If the race was successful, play a little but forward so that we can see the times.
    if util.readProgress() >= 3 then
      client.unpause()
      print ("Time (seconds):", util.readTimer())
      for i=1, RACE_END_FRAMES do emu.frameadvance() end
    end

    -- Go to the next track.
    state = state + 1
    if state > #TRACKS then state = 1 end
end
