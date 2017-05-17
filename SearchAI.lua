-- Each step forward lasts this many frames.
FRAMES_PER_STEP = 30

FORWARD_FRAMES = 60

-- The steering is discretized into this many bins.
STEERING_BINS = 5

-- The depth to search.
SEARCH_DEPTH = 1

-- Read the current progress in the course from memory.
PROGRESS_ADRESS = 0x162FD8
function read_progress() return mainmemory.readfloat(PROGRESS_ADRESS, true) end

client.unpause()

event.onexit(function()
  client.pause()
  client.unpause_av()
end)

function eval_actions(actions)
  savestate.load('root.state')
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

  return read_progress()
end

function best_next_action(actions_so_far)
  if #actions_so_far == SEARCH_DEPTH then
    return nil, eval_actions(actions_so_far)
  end

  best_action, best_score = nil, -math.huge
  for next_action=-1, 1, 2/(STEERING_BINS - 1) do
    table.insert(actions_so_far, next_action)
    _, score = best_next_action(actions_so_far)
    if score > best_score then
      best_score = score
      best_action = next_action
    end
    table.remove(actions_so_far)
  end

  return best_action, best_score
end

while true do
  client.pause_av()
  start_time = os.time()
  savestate.save('root.state')
  action, score = best_next_action({})
  end_time = os.time()

  print("Action:", action, "Score:", score, "Time:", end_time - start_time)

  savestate.load('root.state')
  client.unpause_av()
  for i=1, FRAMES_PER_STEP do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = 127 * action})
    emu.frameadvance()
  end
end

client.pause()
