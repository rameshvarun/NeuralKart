FRAMES_FORWARD = 60
NUM_ANGLES = 51
USE_MAPPING = true

function math.sign(x)
  if x > 0 then return 1
  elseif x < 0 then return -1
  else return 0 end
end

assert(NUM_ANGLES % 2 == 1, "NUM_ANGLES must be odd.")

function linspace(start, vend, divs)
  local val = start
  local step_size = (vend - start) / (divs - 1)
  local i = -1
  return function ()
    i = i + 1
    if i < divs - 1 then
      return start + i * step_size
    elseif i == divs - 1 then
      return vend
    end
  end
end

ANGLES = {}
RAW = {}
for i in linspace(-1, 1, NUM_ANGLES) do
  table.insert(RAW, i)
  if USE_MAPPING then
    table.insert(ANGLES, math.sign(i) * math.sqrt(math.abs(i) * 0.24 + 0.01))
  else
    table.insert(ANGLES, i)
  end
end
assert(#ANGLES == NUM_ANGLES)

-- The save state will be temporarily stored in this file when performing a search.
local TMP_DIR = io.popen("echo %TEMP%"):read("*l")
local STATE_FILE = TMP_DIR .. '\\root.state'

savestate.save(STATE_FILE)

client.unpause()
event.onexit(function()
  client.pause()
  savestate.load(STATE_FILE)
end)

function readx() return mainmemory.readfloat(0x0F69A4, true) end

for i, angle in ipairs(ANGLES) do
  savestate.load(STATE_FILE)
  emu.frameadvance()
  local start_x = readx()

  for i=1, FRAMES_FORWARD do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] =  127 * angle})
    emu.frameadvance()
  end

  if USE_MAPPING then
    print("Raw = ", RAW[i], "Joystick = ", angle, "X Difference =", readx() - start_x)
  else
    print("Joystick = ", angle, "X Difference =", readx() - start_x)
  end
end
