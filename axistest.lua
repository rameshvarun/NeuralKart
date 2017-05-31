--[[ BEGIN CONFIGURATION ]]--
FRAMES_FORWARD = 60
NUM_ANGLES = 51
USE_MAPPING = true
--[[ END CONFIGURATION ]]--

local util = require("util")

assert(NUM_ANGLES % 2 == 1, "NUM_ANGLES must be odd.")

JOYSTICK, STEER = {}, {}
for steer in util.linspace(-1, 1, NUM_ANGLES) do
  table.insert(STEER, steer)
  table.insert(JOYSTICK, util.convertSteerToJoystick(steer, USE_MAPPING))
end
assert(#JOYSTICK == NUM_ANGLES)

-- The save state will be temporarily stored in this file when performing a search.
local STATE_FILE = util.getTMPDir() .. '\\root.state'

savestate.save(STATE_FILE)

client.unpause()
event.onexit(function()
  client.pause()
  savestate.load(STATE_FILE)
end)

for i, joystick in ipairs(JOYSTICK) do
  savestate.load(STATE_FILE)
  emu.frameadvance()
  local start_x = util.readPlayerX()

  for i=1, FRAMES_FORWARD do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = joystick})
    emu.frameadvance()
  end

  if USE_MAPPING then
    print("Steer = ", STEER[i], "Joystick = ", joystick, "X Difference =",  util.readPlayerX() - start_x)
  else
    print("Joystick = ", joystick, "X Difference =",  util.readPlayerX() - start_x)
  end
end
