local util = {}

function util.getWorkingDir()
  return io.popen("cd"):read("*l")
end

-- Return the location of the TMP dir on this computer, caching the result.
local TMP_DIR = nil
function util.getTMPDir()
  if TMP_DIR == nil then TMP_DIR = io.popen("echo %TEMP%"):read("*l") end
  return TMP_DIR
end

-- Sign, Clamp, and Lerp functions, taken from lume
function util.sign(x)
  return x < 0 and -1 or 1
end
function util.clamp(x, min, max)
  return x < min and min or (x > max and max or x)
end
function util.lerp(a, b, amount)
  return a + (b - a) * util.clamp(amount, 0, 1)
end

function util.linspace(start, vend, divs)
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

function util.finiteDifferences(nums)
  local diffs = {}
  for i, x in ipairs(nums) do
    if i > 1 then table.insert(diffs, x - nums[i - 1]) end
  end
  return diffs
end

function util.bendingEnergy(nums)
  local accum = 0
  local second_deriv = util.finiteDifferences(util.finiteDifferences(nums))
  for _, x in ipairs(second_deriv) do accum = accum + x * x end
  return accum
end

function util.readPlayerX()
  return mainmemory.readfloat(0x0F69A4, true)
end

-- Read the current progress in the course from memory.
util.PROGRESS_ADDRESS = 0x1644D0
function util.readProgress()
  return mainmemory.readfloat(util.PROGRESS_ADDRESS, true)
end

-- Read the velocity of the player from meory.
util.VELOCITY_ADDRESS = 0x0F6BBC
function util.readVelocity()
  return mainmemory.readfloat(util.VELOCITY_ADDRESS, true)
end

-- The current match timer.
util.TIMER_ADDRESS = 0x0DC598
function util.readTimer()
  return mainmemory.readfloat(util.TIMER_ADDRESS, true)
end

util.STEER_MIN, util.STEER_MAX = -1, 1
util.JOYSTICK_MIN, util.JOYSTICK_MAX = -128, 127

function util.convertSteerToJoystick(steer, use_mapping)
  -- Ensure that steer is between -1 and 1
  steer = util.clamp(steer, util.STEER_MIN, util.STEER_MAX)

  -- If we are using our mapping, map the linaer steer space to the joystick space.
  if use_mapping == true then
    steer = util.sign(steer) * math.sqrt(math.abs(steer) * 0.24 + 0.01)
  end

  -- Map the -1 to 1 steer into an integer -128 to 127 space.
  local alpha = (steer + 1)/2
  return math.floor(util.lerp(util.JOYSTICK_MIN, util.JOYSTICK_MAX, alpha))
end

return util
