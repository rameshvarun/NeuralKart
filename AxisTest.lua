--[[
AxisTest.lua

This script is used for testing how different Joystick inputs change Mario's trajectory (it's not linear).
To use it, Mario needs to be facing along the Y-axis, such that turns to the left and right will
cause negative and positive X-displacement, respectively. We used this script to calculate our
input-space remapping, so that all the options to the SearchAI are linearly spaced.
]]--

--[[ BEGIN CONFIGURATION ]]--
FRAMES_FORWARD = 60 -- The number of frames to play with each posible joystick value.
NUM_ANGLES = 51 -- How many different angles to test.
USE_MAPPING = true -- Whether or not to use input-space remapping.
--[[ END CONFIGURATION ]]--

assert(NUM_ANGLES % 2 == 1, "NUM_ANGLES must be odd.")

local util = require("util")

--[[ Generate the Joystick values. JOYSTICK (signed byte) is what's actually send to the joystick,
while STEER (from -1 to 1) is linearly spaced. ]]--
JOYSTICK, STEER = {}, {}
for steer in util.linspace(-1, 1, NUM_ANGLES) do
  table.insert(STEER, steer)
  table.insert(JOYSTICK, util.convertSteerToJoystick(steer, USE_MAPPING))
end
assert(#JOYSTICK == NUM_ANGLES)

-- The save state will be temporarily stored in this file when performing a search.
local STATE_FILE = util.getTMPDir() .. '\\root.state'
savestate.save(STATE_FILE)

-- On exit, pause the game and load the state that we started at.
event.onexit(function()
  client.pause()
  savestate.load(STATE_FILE)
end)

client.unpause()

for i, joystick in ipairs(JOYSTICK) do
  savestate.load(STATE_FILE)
  local start_x = util.readPlayerX()

  -- Play forward with the selected joystick value.
  for i=1, FRAMES_FORWARD do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] = joystick})
    emu.frameadvance()
  end

  -- Pring the resulting X-displacement.
  if USE_MAPPING then
    print("Steer = ", STEER[i], "Joystick = ", joystick, "X Difference =",  util.readPlayerX() - start_x)
  else
    print("Joystick = ", joystick, "X Difference =",  util.readPlayerX() - start_x)
  end
end
