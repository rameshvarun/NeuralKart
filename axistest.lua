FRAMES_FORWARD = 60

function math.sign(x)
  if x > 0 then return 1
  elseif x < 0 then return -1
  else return 0 end
end

ANGLES = {}

for i=-1, 1, 2*(1) / 12 do
  table.insert(ANGLES, math.sign(i) * math.sqrt(math.abs(i) * 0.24 + 0.01))
end

print("Number of angles:", #ANGLES)
-- ANGLES = {-1, -0.5, -0.45, -0.4, -0.35, -0.3, -0.25, 0, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 1}

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

for _, angle in ipairs(ANGLES) do
  savestate.load(STATE_FILE)
  emu.frameadvance()
  local start_x = readx()

  for i=1, FRAMES_FORWARD do
    joypad.set({["P1 A"] = true})
    joypad.setanalog({["P1 X Axis"] =  127 * angle})
    emu.frameadvance()
  end

  print("Angle = ", angle, "X Difference =", readx() - start_x)
end
