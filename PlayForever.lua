--[[ This script plays forever in a loop, for purposes of demoing the AI. ]]--

local util = require("util")
local play = loadfile("Play.lua")

local START_STATE_FILE = util.getTMPDir() .. '\\play-forever-start.state'
savestate.save(START_STATE_FILE)

client.unpause()
event.onexit(function()
  client.pause()
  savestate.load(START_STATE_FILE)
end)

print("Mode:", util.readMode(), "Course:", util.readCourse())

while true do
    -- Start from the beginning and play.
    savestate.load(START_STATE_FILE)
    play()
end
