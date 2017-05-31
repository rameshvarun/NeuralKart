local util = {}

function util.getWorkingDir()
  return io.popen("cd"):read("*l")
end

function util.getTMPDir()
  return io.popen("echo %TEMP%"):read("*l")
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

function util.readPlayerX() return mainmemory.readfloat(0x0F69A4, true) end

return util
