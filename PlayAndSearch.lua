--[[ BEGIN CONFIGURATION ]]--
local FRAMES_TO_PLAY_MIN = 30
local FRAMES_TO_PLAY_MAX = 300
local FRAMES_TO_SEARCH = 30 * 4
local TRAIN_PERIOD = 3
--[[ END CONFIGURATION ]]--

-- Lua doesn't seed the random number generator by default, so we need to seed it with the time.
math.randomseed(os.time())

local WORKING_DIR = io.popen("cd"):read("*l")
local TMP_DIR = io.popen("echo %TEMP%"):read("*l")

local START_STATE_FILE = TMP_DIR .. '\\play-and-search-start.state'
savestate.save(START_STATE_FILE)

local PRE_SEARCH_STATE_FILE = TMP_DIR .. '\\before-search.state'

-- Read the current progress in the course from memory.
local PROGRESS_ADDRESS = 0x1644D0
function read_progress() return mainmemory.readfloat(PROGRESS_ADDRESS, true) end

client.unpause()
event.onexit(function()
  client.pause()
end)

local PLAY_SOURCE = io.open("Play.lua", "rb"):read("*all")
local play = loadstring(PLAY_SOURCE)

local SEARCH_SOURCE = io.open("SearchAI.lua", "rb"):read("*all")
local search = loadstring(SEARCH_SOURCE)

local iteration = 1
while true do
  savestate.load(START_STATE_FILE)
  local progress = read_progress()

  while read_progress() < 3 do
    play(math.random(FRAMES_TO_PLAY_MIN, FRAMES_TO_PLAY_MAX))
    if read_progress() > progress then
      progress = read_progress()
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
