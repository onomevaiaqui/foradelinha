local Runtime, boot_error
local ok, result = pcall(function()
  require "palette"
  for index, color in ipairs(Palette or {}) do ui.palset(index - 1, color) end
  local runtime = require "lupix_runtime"
  local scene = require("lupix_scenes.Main")
  local entry = require "lupix_entry"
  runtime.start(scene, entry)
  return runtime
end)
if ok then Runtime = result else boot_error = tostring(result) end
local function show_error(message)
  ui.camera()
  ui.cls(0)
  ui.print("LUPIX - FALHA NO JOGO", 8, 8, 7)
  local text, y = tostring(message or "Erro desconhecido"), 28
  for start = 1, #text, 56 do
    if y > 250 then break end
    ui.print(string.sub(text, start, start + 55), 8, y, 7)
    y = y + 16
  end
end
function update(frame)
  if boot_error then show_error(boot_error); return end
  local frame_ok, frame_error = pcall(function() Runtime.update(frame) end)
  if not frame_ok then show_error(frame_error) end
end
