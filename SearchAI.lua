--[[ BEGIN CONFIGURATION ]]--
SEARCH_STEP_FRAMES = 30 -- Each step forward lasts this many frames.
SEARCH_FORWARD_FRAMES = 60

-- When you actually execute a move, play for this many frames. This should stay at 30 to keep
-- the framerate of image capture constant.
PLAY_FRAMES = 30

STEERING_BINS = 21 -- The steering is discretized into this many bins.
SEARCH_DEPTH = 1 -- The depth to search.

PROGRESS_WEIGHT = 1
VELOCITY_WEIGHT = 0.1

USE_MAPPING = true
--[[ END CONFIGURATION ]]--

local chunk_args = {...}
local FRAMES_TO_SEARCH = chunk_args[1]
if FRAMES_TO_SEARCH ~= nil then print("Searching for " .. FRAMES_TO_SEARCH .. " frames.") end

local util = require("util")

-- The save state will be temporarily stored in this file when performing a search.
local STATE_FILE = util.getTMPDir() .. '\\root.state'

-- Generate a recording id and create a folder for that recording.
local uuid = require("lualibs.uuid"); uuid.seed()
os.execute('mkdir recordings')
local RECORDING_ID = uuid()
print("Recording ID:", RECORDING_ID)
local RECORDING_FOLDER = 'recordings\\search-' .. RECORDING_ID
os.execute('mkdir ' .. RECORDING_FOLDER)

client.unpause()
client.speedmode(800)

function onexit()
  if steering_file ~= nil then
    steering_file:close()
  end

  client.pause()
  savestate.load(STATE_FILE)
  client.speedmode(100)
  client.unpause_av()
end
local exit_guid = event.onexit(onexit)

function eval_actions(actions)
  savestate.load(STATE_FILE)

  local start_progress = util.readProgress()

  for _, action in ipairs(actions) do
    for i=1, SEARCH_STEP_FRAMES do
      joypad.set({["P1 A"] = true})
      joypad.setanalog({["P1 X Axis"] = util.convertSteerToJoystick(action, USE_MAPPING)})
      emu.frameadvance()
    end
  end

  for i=1, SEARCH_FORWARD_FRAMES do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = 0})
    emu.frameadvance()
  end

  local end_progress = util.readProgress()

  if end_progress > start_progress then
    return PROGRESS_WEIGHT * util.readProgress() + VELOCITY_WEIGHT * util.readVelocity()
  else
    return PROGRESS_WEIGHT * util.readProgress()
  end
end

function best_next_action(actions_so_far)
  if #actions_so_far == SEARCH_DEPTH then
    return nil, eval_actions(actions_so_far)
  end

  local best_action, best_score = nil, -math.huge
  for action in util.linspace(-1, 1, STEERING_BINS) do
    table.insert(actions_so_far, action)
    local _, score = best_next_action(actions_so_far, action)
    if score > best_score then
      best_score = score
      best_action = action
    end
    table.remove(actions_so_far)
  end

  return best_action, best_score
end

local recording_frame = 1
local steering_file = io.open(RECORDING_FOLDER .. '\\steering.txt', 'w')
while util.readProgress() < 3 do
  client.pause_av()
  start_time = os.time()
  savestate.save(STATE_FILE)
  action, score = best_next_action({})

  end_time = os.time()

  print("Action:", action, "Score:", score, "Time:", end_time - start_time)

  savestate.load(STATE_FILE)

  client.screenshot(RECORDING_FOLDER .. '\\' .. recording_frame .. '.png')
  steering_file:write(action .. '\n')
  steering_file:flush()
  recording_frame = recording_frame + 1

  client.unpause_av()
  for i=1, PLAY_FRAMES do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] =  util.convertSteerToJoystick(action, USE_MAPPING)})
    emu.frameadvance()

    if FRAMES_TO_SEARCH ~= nil then FRAMES_TO_SEARCH = FRAMES_TO_SEARCH - 1 end
  end

  -- If we've finished the amount of frames we were asked to search, then stop.
  if FRAMES_TO_SEARCH ~= nil and FRAMES_TO_SEARCH == 0 then break end
end

savestate.save(STATE_FILE)

onexit()
event.unregisterbyid(exit_guid)
