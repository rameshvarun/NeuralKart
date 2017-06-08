--[[ BEGIN CONFIGURATION ]]--
local FRAMES_TO_PLAY_MIN = 60
local FRAMES_TO_PLAY_MAX = 120
local FRAMES_TO_SEARCH = 30 * 4
local TRAIN_PERIOD = 2
--[[ END CONFIGURATION ]]--

local util = require("util")

local course, mode = util.readCourse(), util.readMode()
print("Mode:", util.readMode(), "Course:", util.readCourse())

-- Ensure that there is a recoridngs folder, as well as a subfolder for the current track-mode combination.
os.execute('mkdir recordings\\' .. course .. '\\' .. mode)

-- Lua doesn't seed the random number generator by default, so we need to seed it with the time.
math.randomseed(os.time())

local START_STATE_FILE = util.getTMPDir() .. '\\play-and-search-start.state'
savestate.save(START_STATE_FILE)

local PRE_SEARCH_STATE_FILE = util.getTMPDir() .. '\\before-search.state'
local POST_SEARCH_STATE_FILE1 = util.getTMPDir() .. '\\post-search1.state'
local POST_SEARCH_STATE_FILE2 = util.getTMPDir() .. '\\post-search2.state'
local POST_SEARCH_STATE_FILE3 = util.getTMPDir() .. '\\post-search3.state'
savestate.save(PRE_SEARCH_STATE_FILE)
savestate.save(POST_SEARCH_STATE_FILE1)
savestate.save(POST_SEARCH_STATE_FILE2)
savestate.save(POST_SEARCH_STATE_FILE3)



client.unpause()
event.onexit(function()
  client.pause()
end)

local play = loadfile("Play.lua")
local search = loadfile("SearchAI.lua")

local iteration = 1
local stuck_counter = 0
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
    PLAY_FRAMES = math.random(FRAMES_TO_PLAY_MIN, FRAMES_TO_PLAY_MAX)
    if stuck_counter > 1 then
      PLAY_FRAMES = 150
    end
    play(PLAY_FRAMES)
    if util.readProgress() > progress + .01 then
      stuck_counter = 0
      print('We made progress! Current Progress:', progress)
      progress = util.readProgress()
    else
      stuck_counter = stuck_counter + 1
      print("We got stuck,current counter:", stuck_counter)
      if stuck_counter > 2 then
        print("We are stuck! Resetting.")
        break
      end
      if stuck_counter > 0 then
        print('resetting from previous state.')
        savestate.load(POST_SEARCH_STATE_FILE3)
      end
    end

    savestate.save(PRE_SEARCH_STATE_FILE)

    savestate.load(POST_SEARCH_STATE_FILE1)
    savestate.save(POST_SEARCH_STATE_FILE3)

    --savestate.load(POST_SEARCH_STATE_FILE1)
    --savestate.save(POST_SEARCH_STATE_FILE2)

    savestate.load(PRE_SEARCH_STATE_FILE)

    recording_frame = search(FRAMES_TO_SEARCH, RECORDING_FOLDER, recording_frame)
    savestate.save(POST_SEARCH_STATE_FILE1)
    savestate.load(PRE_SEARCH_STATE_FILE)
  end

  iteration = iteration + 1
  if iteration % TRAIN_PERIOD == 0 then
    print("Running train.py...")
    os.execute("cmd.exe @cmd /c python35 train.py " .. course)
  end
end
