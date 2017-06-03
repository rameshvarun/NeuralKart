--[[ BEGIN CONFIGURATION ]]--
local FRAMES_TO_PLAY_MIN = 30
local FRAMES_TO_PLAY_MAX = 200
local FRAMES_TO_SEARCH = 30 * 4
local TRAIN_PERIOD = 3
--[[ END CONFIGURATION ]]--

local util = require("util")

local course = util.readCourse()
local mode = util.readMode()

-- Ensure that there is a recoridngs folder, as well as a subfolder for the current track-mode combination.
os.execute('mkdir recordings\\' .. course .. '\\' .. mode)

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
  -- Generate a recording id.
  local RECORDING_ID = util.generateUUID(); print("Recording ID:", RECORDING_ID)

  -- Create a folder for this recording.
  local RECORDING_FOLDER = 'recordings\\' .. course .. '\\' .. mode .. '\\play-and-search-' .. RECORDING_ID
  os.execute('mkdir ' .. RECORDING_FOLDER)

  -- Create an empty steering file that will be appended to.
  os.execute('type nul > ' .. RECORDING_FOLDER .. '\\steering.txt')

  local recording_frame = 1

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
    recording_frame = search(FRAMES_TO_SEARCH, RECORDING_FOLDER, recording_frame)
    savestate.load(PRE_SEARCH_STATE_FILE)
  end

  iteration = iteration + 1
  if iteration % TRAIN_PERIOD == 0 then
    print("Running train.py...")
    os.execute("cmd.exe @cmd /c python train.py " .. course)
  end
end
