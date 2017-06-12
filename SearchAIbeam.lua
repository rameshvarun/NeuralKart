--[[ BEGIN CONFIGURATION ]]--
SEARCH_STEP_FRAMES = 45 -- Each step forward lasts this many frames.
SEARCH_FORWARD_FRAMES = 75

-- When you actually execute a move, play for this many frames. This should stay at 30 to keep
-- the framerate of image capture constant.
PLAY_FRAMES = 30

STEERING_BINS = 11 -- The steering is discretized into this many bins.

--need to check depth > 1
SEARCH_DEPTH = 1 -- The depth to search.
BEAM_WIDTH = 3

BENDING_ENERGY_WINDOW = 4

PROGRESS_WEIGHT = 1
VELOCITY_WEIGHT = 0.05
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
local STATE_FILE_TABLE = {}
local TEMP_STATE_FILE_TABLE = {}
local action_table = {}
local before_step_table = {}
for k = 1, BEAM_WIDTH, 1 do
  table.insert(action_table, 0)
  local BEAM_STATE_FILE = util.getTMPDir() .. '\\' .. k .. '.state'
  local TEMP_FILE = util.getTMPDir() .. '\\' .. k .. 'temp.state'
  local before_state = util.getTMPDir() .. '\\' .. k .. 'before.state'
  savestate.save(BEAM_STATE_FILE)
  table.insert(STATE_FILE_TABLE, BEAM_STATE_FILE)
  table.insert(TEMP_STATE_FILE_TABLE, TEMP_FILE)
  table.insert(before_step_table, before_state)
end

--print('file table', STATE_FILE_TABLE)

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

function eval_actions(actions, actions_history, knum)
  -- Calculate bending energy, which is a measure of the smoothness of the trajectory.
  local bending_energy, window = 0, {}
  for _, action in ipairs(actions) do
    if #window < BENDING_ENERGY_WINDOW then table.insert(window, 1, action) end
  end
  for _, action in ipairs(actions_history) do
    if #window < BENDING_ENERGY_WINDOW then table.insert(window, 1, action) end
  end
  bending_energy = util.bendingEnergy(window)

  savestate.load(STATE_FILE_TABLE[knum])

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

function get_top_k_actions(all_actions)
  sorted = {table.remove(all_actions)}
  --print('sorted', sorted)
  for __, combo in ipairs(all_actions) do
      score = combo[2]
      local iter = 1
      while iter <= #sorted  do
        if score >= sorted[iter][2] then break end
        iter = iter + 1
      end
      table.insert(sorted, iter, combo)
      --print('score ', score)
      --print('actions is:' .. combo[1] .. ' and score is:' .. combo[2] )
    --end 
  end
  local keep = {}
  for k=1,BEAM_WIDTH,1 do
    table.insert(keep, sorted[k])
  end
  --print('keep is', keep, 'all_actions is', all_actions)
  return keep
end


function best_next_action(actions_so_far, actions_history, binnum)
  --print('starting best_action')
  --print('len is', #actions_history, SEARCH_DEPTH)
  if #actions_history == SEARCH_DEPTH then
    --print('checking')
    return {nil, eval_actions(actions_so_far, actions_history, binnum), nil}
  end
  --print('afer check', actions_so_far)
  --local best_action = 0
  --table.insert(actions_so_far, 0)
  --local best_score_table = best_next_action(actions_so_far, actions_history)
  --table.remove(actions_so_far)
  --stores all actions for each branch
  local all_actions  = {}
  for num=1, #actions_so_far, 1 do
    local first_action = 0
    table.insert(actions_so_far[num], 0)
    table.insert(actions_history[num], 0)
    local first_score_list = best_next_action(actions_so_far[num], actions_history[num], num)
    local first_combo = {first_action, first_score_list[2], num}
    table.insert(all_actions, first_combo)
    table.remove(actions_so_far[num])
    table.remove(actions_history[num])
    for action in util.linspace(-1, 1, STEERING_BINS) do
      if math.abs(action) > 1e-5 then
        table.insert(actions_so_far[num], action)
        table.insert(actions_history[num], action)
        local score_list = best_next_action(actions_so_far[num], actions_history[num], num)
        local combo = {action, score_list[2], num}
        table.insert(all_actions, combo)
        --if score > best_score then
        --  best_score = score
        --  best_action = action
        end
      table.remove(actions_so_far[num])
      table.remove(actions_history[num])
      end
    end

  local keep = get_top_k_actions(all_actions)

  return keep
end

local recording_frame = 1
if RECORDING_START_FRAME ~= nil then recording_frame = RECORDING_START_FRAME end

local steering_file = io.open(RECORDING_FOLDER .. '\\steering.txt', 'a')
local actions_history = {}
local actions = {}

--print('right before next action')

for k=1,BEAM_WIDTH,1 do
  table.insert(actions, {})
  table.insert(actions_history, {})
end

--print('actions is', actions)
local tempactions = {}
table.insert(tempactions, {})
--print('tempactions', tempactions)

local temphist = {}
--table.insert(temphist, {})
local best_k = best_next_action(tempactions, actions_history, 1)
--print('prve best k is', best_k)
local best_action = best_k[1][1]

for k=1,#STATE_FILE_TABLE,1 do
  local cur_action = best_k[k][1]
  local best_bin = best_k[k][3]
  --print("Action:", cur_action, "Score:", best_k[k][2], "Knum:", best_k[k][3])
  savestate.load(STATE_FILE_TABLE[best_bin])
  savestate.save(before_step_table[k])
  action_table[k] = cur_action
  for i=1, SEARCH_STEP_FRAMES do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = util.convertSteerToJoystick(cur_action, USE_MAPPING)})
    emu.frameadvance()
  end
  savestate.save(TEMP_STATE_FILE_TABLE[k])

end
for k=1,#STATE_FILE_TABLE,1 do
  savestate.load(TEMP_STATE_FILE_TABLE[k])
  savestate.save(STATE_FILE_TABLE[k])
end

end_time = os.time()

table.insert(actions_history, best_action)

savestate.load(STATE_FILE_TABLE[binnum])

client.screenshot(RECORDING_FOLDER .. '\\' .. recording_frame .. '.png')
steering_file:write(best_action .. '\n')
steering_file:flush()
recording_frame = recording_frame + 1

local start_progress = util.readProgress()

client.unpause_av()
for i=1, PLAY_FRAMES do
  joypad.set({["P1 A"] = true})
  joypad.setanalog({["P1 X Axis"] =  util.convertSteerToJoystick(best_action, USE_MAPPING)})
  emu.frameadvance()
end

--print('starting while loop')
while util.readProgress() < 3 do
  client.pause_av()
  start_time = os.time()
  --savestate.save(STATE_FILE)
  local best_k = best_next_action(actions, actions_history, 1)
  local best_action = best_k[1][1]
  local score = best_k[1][2]

  --save best k states in temp directory
  for k=1,#STATE_FILE_TABLE,1 do

    local cur_action = best_k[k][1]
    local best_bin = best_k[k][3]
    if k == 1 then
      savestate.load(before_step_table[best_bin])
      client.screenshot(RECORDING_FOLDER .. '\\' .. recording_frame .. '.png')
      steering_file:write(action_table[best_bin] .. '\n')
      steering_file:flush()
      recording_frame = recording_frame + 1
    end
    print("Action:", cur_action, "Score:", best_k[k][2], "Knum:", best_k[k][3])
    savestate.load(STATE_FILE_TABLE[best_bin])
    savestate.save(before_step_table[k])
    action_table[k] = cur_action
    for i=1, SEARCH_STEP_FRAMES do
      joypad.set({["P1 A"] = true})
      joypad.setanalog({["P1 X Axis"] = util.convertSteerToJoystick(cur_action, USE_MAPPING)})
      emu.frameadvance()
    end
    savestate.save(TEMP_STATE_FILE_TABLE[k])

  end
  for k=1,#STATE_FILE_TABLE,1 do
    savestate.load(TEMP_STATE_FILE_TABLE[k])
    savestate.save(STATE_FILE_TABLE[k])
  end

  end_time = os.time()

  table.insert(actions_history, best_action)

  savestate.load(STATE_FILE_TABLE[binnum])

  --client.screenshot(RECORDING_FOLDER .. '\\' .. recording_frame .. '.png')
  --steering_file:write(best_action .. '\n')
  --steering_file:flush()

  local start_progress = util.readProgress()

  client.unpause_av()
  for i=1, PLAY_FRAMES do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] =  util.convertSteerToJoystick(best_action, USE_MAPPING)})
    emu.frameadvance()

    if FRAMES_TO_SEARCH ~= nil then FRAMES_TO_SEARCH = FRAMES_TO_SEARCH - 1 end
  end

  local end_progress = util.readProgress()
  if end_progress < start_progress then
    print("Search AI is stuck!")
    break
  end

  -- If we've finished the amount of frames we were asked to search, then stop.
  if FRAMES_TO_SEARCH ~= nil and FRAMES_TO_SEARCH == 0 then 
    print('finished frames')
    break 
  end
end

savestate.save(STATE_FILE)

onexit()
event.unregisterbyid(exit_guid)

return recording_frame
