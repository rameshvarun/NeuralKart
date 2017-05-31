local chunk_args = {...}
local PLAY_FOR_FRAMES = chunk_args[1]
if PLAY_FOR_FRAMES ~= nil then print("Playing for " .. PLAY_FOR_FRAMES .. " frames.") end

local util = require("util")

local SCREENSHOT_FILE = util.getTMPDir() .. '\\predict-screenshot.png'

local tcp = require("lualibs.socket").tcp()
local success, error = tcp:connect('localhost', 36296)
if not success then
  print("Failed to connect to server:", error)
  return
end

tcp:settimeout(0)

client.unpause()

local WAIT_FRAMES = 5

outgoing_message, outgoing_message_index = nil, nil
function request_prediction()
  client.screenshot(SCREENSHOT_FILE)
  outgoing_message = "PREDICT:" .. SCREENSHOT_FILE .. "\n"
  outgoing_message_index = 1
end
request_prediction()

local receive_buffer = ""

function onexit()
  client.pause()
  tcp:close()
end
local exit_guid = event.onexit(onexit)

local current_action = 0

while true do
  -- Process the outgoing message.
  if outgoing_message ~= nil then
    local sent, error, last_byte = tcp:send(outgoing_message, outgoing_message_index)
    if sent ~= nil then
      outgoing_message = nil
      outgoing_message_index = nil
    else
      if error == "timeout" then
        outgoing_message_index = last_byte + 1
      else
        print("Send failed: ", error); break
      end
    end
  end

  local message, error
  message, error, receive_buffer = tcp:receive("*l", receive_buffer)
  if message == nil then
    if error ~= "timeout" then
      print("Receive failed: ", error); break
    end
  else
    current_action = tonumber(message)
    for i=1, WAIT_FRAMES do
      joypad.set({["P1 A"] = true})
      joypad.setanalog({["P1 X Axis"] = 127 * current_action})
      emu.frameadvance()
    end
    request_prediction()
  end

  joypad.set({["P1 A"] = true})
  joypad.setanalog({["P1 X Axis"] = 127 * current_action})
  emu.frameadvance()

  if PLAY_FOR_FRAMES ~= nil then
    if PLAY_FOR_FRAMES > 0 then
      PLAY_FOR_FRAMES = PLAY_FOR_FRAMES - 1
    elseif PLAY_FOR_FRAMES == 0 then break end
  end
end

onexit()
event.unregisterbyid(exit_guid)
