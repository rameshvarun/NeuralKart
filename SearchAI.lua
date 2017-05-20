local WORKING_DIR = io.popen("cd"):read("*l")
local TMP_DIR = io.popen("echo %TEMP%"):read("*l")

-- The save state will be temporarily stored in this file when performing a search.
local STATE_FILE = TMP_DIR .. '\\root.state'

-- Generate a recording id and create a folder for that recording.
local uuid = require("lualibs.uuid"); uuid.seed()
os.execute('mkdir recordings')
local RECORDING_ID = uuid()
print("Recording ID:", RECORDING_ID)
local RECORDING_FOLDER = 'recordings\\search-' .. RECORDING_ID
os.execute('mkdir ' .. RECORDING_FOLDER)

-- Each step forward lasts this many frames.
FRAMES_PER_STEP = 30

FORWARD_FRAMES = 60

-- The steering is discretized into this many bins.
STEERING_BINS = 9

-- The depth to search.
SEARCH_DEPTH = 1

PROGRESS_WEIGHT = 1
VELOCITY_WEIGHT = 0.1

angles = {-0.5, -0.4, -0.3, -0.25, -0.2, 0, 0.2, 0.25, 0.3, 0.4, 0.5}

-- Read the current progress in the course from memory.
PROGRESS_ADDRESS = 0x162FD8
function read_progress() return mainmemory.readfloat(PROGRESS_ADDRESS, true) end

VELOCITY_ADDRESS = 0x0F6BBC
function read_velocity() return mainmemory.readfloat(VELOCITY_ADDRESS, true) end

last_action = 0

client.unpause()

event.onexit(function()
  if steering_file ~= nil then
    steering_file:close()
  end

  client.pause()
  client.unpause_av()
end)

function eval_actions(actions)
  savestate.load(STATE_FILE)
  for _, action in ipairs(actions) do
    for i=1, FRAMES_PER_STEP do
      joypad.set({["P1 A"] = true})
      joypad.setanalog({["P1 X Axis"] = 127 * action})
      emu.frameadvance()
    end
  end

  for i=1, FORWARD_FRAMES do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = 0})
    emu.frameadvance()
  end

  print("Current Score:", PROGRESS_WEIGHT * read_progress() + VELOCITY_WEIGHT * read_velocity())
  print(unpack(actions))

  return PROGRESS_WEIGHT * read_progress() + VELOCITY_WEIGHT * read_velocity()
end

function best_next_action(actions_so_far, last_action)
  if #actions_so_far == SEARCH_DEPTH then
    return nil, eval_actions(actions_so_far)
  end

  local best_action, best_score = nil, -math.huge
  -- local left_range = last_action - .5
  -- local right_range = last_action + .5
  for _, relative_angle in ipairs(angles) do
    next_action = relative_angle
    if next_action >= -1 and next_action <= 1 then
      table.insert(actions_so_far, next_action)
      local _, score = best_next_action(actions_so_far, next_action)
      if score > best_score then
        best_score = score
        best_action = next_action
      end
      table.remove(actions_so_far)
    end
  end

  return best_action, best_score
end

local recording_frame = 1
local steering_file = io.open(RECORDING_FOLDER .. '\\steering.txt', 'w')
while true do
  client.pause_av()
  start_time = os.time()
  savestate.save(STATE_FILE)
  action, score = best_next_action({}, last_action)
  last_action = action

  end_time = os.time()

  print("Action:", action, "Score:", score, "Time:", end_time - start_time)

  savestate.load(STATE_FILE)

  client.screenshot(RECORDING_FOLDER .. '\\' .. recording_frame .. '.png')
  steering_file:write(action .. '\n')
  steering_file:flush()
  recording_frame = recording_frame + 1

  client.unpause_av()
  for i=1, FRAMES_PER_STEP do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = 127 * action})
    emu.frameadvance()
  end
end

steering_file:close()
client.pause()
