--[[ BEGIN CONFIGURATION ]]--
local FRAMES_TO_PLAY_MIN = 30
local FRAMES_TO_PLAY_MAX = 200
local FRAMES_TO_SEARCH = 30 * 4
local TRAIN_PERIOD = 3
--[[ END CONFIGURATION ]]--

local util = require("util")

-- Lua doesn't seed the random number generator by default, so we need to seed it with the time.
math.randomseed(os.time())

local START_STATE_FILE = util.getTMPDir() .. '\\play-and-search-start.state'
savestate.save(START_STATE_FILE)

local PRE_SEARCH_STATE_FILE = util.getTMPDir() .. '\\before-search.state'

client.unpause()
event.onexit(function()
  client.pause()
end)

local play = loadfile("Play.lua")
local search = loadfile("SearchAI.lua")

local iteration = 1
while true do
  savestate.load(START_STATE_FILE)
  local progress = util.readProgress()

  while util.readProgress() < 3 do
    play(math.random(FRAMES_TO_PLAY_MIN, FRAMES_TO_PLAY_MAX))
    if util.readProgress() > progress then
      progress = util.readProgress()
    else
      print("We are stuck! Resetting.")
      break
    end

    savestate.save(PRE_SEARCH_STATE_FILE)
    search(FRAMES_TO_SEARCH)
    savestate.load(PRE_SEARCH_STATE_FILE)
  end

  iteration = iteration + 1
  if iteration % TRAIN_PERIOD == 0 then
    print("Running train.py...")
    os.execute("cmd.exe @cmd /c python train.py")
  end
end
