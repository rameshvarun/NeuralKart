--[[ BEGIN CONFIGURATION ]]--
-- The amount of frames to play before we start to search again is uniformly distributed between
-- FRAMES_TO_PLAY_MIN and FRAMES_TO_PLAY_MAX.
local FRAMES_TO_PLAY_MIN = 30
local FRAMES_TO_PLAY_MAX = 100

local FRAMES_TO_SEARCH = 30 * 4 -- How many frames we should search for whenever the search AI takes over.
local TRAIN_PERIOD = 2 -- How often to train.

-- Set this to a pair of values if you only want to search within a certain progress region.
local HOTSPOT = nil
--[[ END CONFIGURATION ]]--

local util = require("util")
local course, mode = util.readCourse(), util.readMode()
print("Mode:", util.readMode(), "Course:", util.readCourse())

-- Ensure that there is a recoridngs folder, as well as a subfolder for the current track-mode combination.
os.execute('mkdir recordings\\' .. course .. '\\' .. mode)

-- Lua doesn't seed the random number generator by default, so we need to seed it with the time.
math.randomseed(os.time())

-- Store the state when the script is started as the "beginning" state that all iterations will start from.
local START_STATE_FILE = util.getTMPDir() .. '\\play-and-search-start.state'
savestate.save(START_STATE_FILE)

-- The PRE_SEARCH_STATE is used as a bookmark so that we can jump into the search AI, and then return
-- to where the Real-time AI left off.
local PRE_SEARCH_STATE_FILE = util.getTMPDir() .. '\\before-search.state'

client.unpause()
event.onexit(function()
  client.pause()
end)

local play = loadfile("Play.lua")
local search = loadfile("SearchAI.lua")

local iteration = 1
while true do
  -- Generate a recording id and create a folder.
  local RECORDING_ID = util.generateUUID(); print("Recording ID:", RECORDING_ID)
  local RECORDING_FOLDER = 'recordings\\' .. course .. '\\' .. mode .. '\\play-and-search-' .. RECORDING_ID
  os.execute('mkdir ' .. RECORDING_FOLDER)

  -- Create an empty steering file that will be appended to.
  os.execute('type nul > ' .. RECORDING_FOLDER .. '\\steering.txt')

  -- A recovery state if the Play AI gets stuck. In that case, we reset to the last time the
  -- search AI made progress.
  local RECOVERY_STATE_FILE = util.getTMPDir() .. '\\recovery-' .. RECORDING_ID .. '.state'

  local recording_frame = 1
  savestate.load(START_STATE_FILE)
  local progress = util.readProgress()

  while util.readProgress() < 3 do
    PLAY_FRAMES = math.random(FRAMES_TO_PLAY_MIN, FRAMES_TO_PLAY_MAX)
    play(PLAY_FRAMES)

    if util.readProgress() > progress then
      progress = util.readProgress()
    else
      -- If the play AI made no progress, reset to our recover state
      print ("Play AI is stuck. Restting to recovery state...")
      savestate.load(RECOVERY_STATE_FILE)
    end

    if HOTSPOT == nil or (util.readProgress() % 1 >= HOTSPOT[1] and util.readProgress() % 1 <= HOTSPOT[2]) then
      savestate.save(PRE_SEARCH_STATE_FILE)

      local pre_search_progress = util.readProgress()
      recording_frame = search(FRAMES_TO_SEARCH, RECORDING_FOLDER, recording_frame)
      local post_search_progress = util.readProgress()

      if post_search_progress > pre_search_progress then
        savestate.save(RECOVERY_STATE_FILE) -- If the search AI made progress, save th a recovery state.
      else
        break -- If the search AI is stuck, we basically have to reset.
      end

      savestate.load(PRE_SEARCH_STATE_FILE)
    end
  end

  iteration = iteration + 1
  if iteration % TRAIN_PERIOD == 0 then
    print("Running train.py...")
    os.execute("cmd.exe @cmd /c python3 train.py " .. course)
  end
end
