local WORKING_DIR = io.popen("cd"):read("*l")
local PYTHON_LOC = io.popen("where python"):read("*l")
local TMP_DIR = io.popen("echo %TEMP%"):read("*l")
print("Working Dir:", WORKING_DIR)
print("Python Location:", PYTHON_LOC)
print("TEMP Directory:", TMP_DIR)

local SCREENSHOT_FILE = TMP_DIR .. '\\predict-screenshot.png'

local tcp = require("lualibs.socket").tcp()


local port = nil
while true do
  local line = server:read("*line")
  port = line:match("Listening on Port: (%d+)")
  if port ~= nil then break end
end

print ("Server running on port:", port)
tcp:connect('localhost', port)

client.unpause()

while true do
  client.screenshot(SCREENSHOT_FILE)
  tcp:send("PREDICT:" .. SCREENSHOT_FILE .. "\n")
  local s, status, partial = tcp:receive("*l")
  if status == "closed" then break end

  print(s or partial)
  emu.frameadvance()
end

event.onexit(function()
  client.pause()
  tcp:send("QUIT\n")
end)
