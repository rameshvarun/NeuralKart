--[[ BEGIN CONFIGURATION ]]--
SEARCH_STEP_FRAMES = 30 -- Each step forward lasts this many frames.
SEARCH_FORWARD_FRAMES = 60

-- When you actually execute a move, play for this many frames. This should stay at 30 to keep
-- the framerate of image capture constant.
PLAY_FRAMES = 30

STEERING_BINS = 11 -- The steering is discretized into this many bins.
SEARCH_DEPTH = 1 -- The depth to search.

BENDING_ENERGY_WINDOW = 4

PROGRESS_WEIGHT = 1
VELOCITY_WEIGHT = 0.1
BENDING_ENERGY_WEIGHT = 0

USE_MAPPING = true
--[[ END CONFIGURATION ]]--

local chunk_args = {...}
local FRAMES_TO_SEARCH = chunk_args[1]
local RECORDING_FOLDER, RECORDING_START_FRAME = chunk_args[2], chunk_args[3]

if FRAMES_TO_SEARCH ~= nil then print("Searching for " .. FRAMES_TO_SEARCH .. " frames.") end

local util = require("util")

-- The save state will be temporarily stored in this file when performing a search.
local STATE_FILE = util.getTMPDir() .. '\\root.state'

local mode = util.readMode()
local course = util.readCourse()

if RECORDING_FOLDER == nil then
  -- Ensure that there is a recoridngs folder, as well as a subfolder for the current track-mode combination.
  os.execute('mkdir recordings\\' .. course .. '\\' .. mode)

  -- Generate a recording id.
  local RECORDING_ID = util.generateUUID()
  print("Recording ID:", RECORDING_ID)

  -- Create a folder for this recording.
  RECORDING_FOLDER = 'recordings\\' .. course .. '\\' .. mode .. '\\search-' .. RECORDING_ID
  os.execute('mkdir ' .. RECORDING_FOLDER)

  -- Create an empty steering file that will be appended to.
  os.execute('type nul > ' .. RECORDING_FOLDER .. '\\steering.txt')
end

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

function eval_actions(actions, actions_history)
  -- Calculate bending energy, which is a measure of the smoothness of the trajectory.
  local bending_energy, window = 0, {}
  for _, action in ipairs(actions) do
    if #window < BENDING_ENERGY_WINDOW then table.insert(window, 1, action) end
  end
  for _, action in ipairs(actions_history) do
    if #window < BENDING_ENERGY_WINDOW then table.insert(window, 1, action) end
  end
  bending_energy = util.bendingEnergy(window)

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
    return PROGRESS_WEIGHT * util.readProgress() + VELOCITY_WEIGHT * util.readVelocity() - BENDING_ENERGY_WEIGHT * bending_energy
  else
    return PROGRESS_WEIGHT * (util.readProgress() - 3)
  end
end

function best_next_action(actions_so_far, actions_history)
  if #actions_so_far == SEARCH_DEPTH then
    return nil, eval_actions(actions_so_far, actions_history)
  end

  local best_action = 0
  table.insert(actions_so_far, 0)
  local _, best_score = best_next_action(actions_so_far, actions_history)
  table.remove(actions_so_far)

  for action in util.linspace(-1, 1, STEERING_BINS) do
    if math.abs(action) > 1e-5 then
      table.insert(actions_so_far, action)
      local _, score = best_next_action(actions_so_far, actions_history)
      if score > best_score then
        best_score = score
        best_action = action
      end
       table.remove(actions_so_far)
    end
  end

  return best_action, best_score
end

local recording_frame = 1
if RECORDING_START_FRAME ~= nil then recording_frame = RECORDING_START_FRAME end

local steering_file = io.open(RECORDING_FOLDER .. '\\steering.txt', 'a')
local actions_history = {}
while util.readProgress() < 3 do
  client.pause_av()
  start_time = os.time()
  savestate.save(STATE_FILE)
  action, score = best_next_action({}, actions_history)

  end_time = os.time()

  print("Action:", action, "Score:", score, "Time:", end_time - start_time)
  table.insert(actions_history, action)

  savestate.load(STATE_FILE)

  client.screenshot(RECORDING_FOLDER .. '\\' .. recording_frame .. '.png')
  steering_file:write(action .. '\n')
  steering_file:flush()
  recording_frame = recording_frame + 1

  local start_progress = util.readProgress()

  client.unpause_av()
  for i=1, PLAY_FRAMES do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] =  util.convertSteerToJoystick(action, USE_MAPPING)})
    emu.frameadvance()

    if FRAMES_TO_SEARCH ~= nil then FRAMES_TO_SEARCH = FRAMES_TO_SEARCH - 1 end
  end

  local end_progress = util.readProgress()
  if end_progress < start_progress then
    print("Search AI is stuck!")
    break
  end

  -- If we've finished the amount of frames we were asked to search, then stop.
  if FRAMES_TO_SEARCH ~= nil and FRAMES_TO_SEARCH == 0 then break end
end

savestate.save(STATE_FILE)

onexit()
event.unregisterbyid(exit_guid)

return recording_frame
