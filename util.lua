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

function util.sign(x)
  if x > 0 then return 1
  elseif x < 0 then return -1
  else return 0 end
end

function util.clamp(x, min, max)
  return x < min and min or (x > max and max or x)
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

return util
