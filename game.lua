-- Lupi assigns palette indices while processing the PNG sources.
-- Keep the editor's logical colors stable without replacing that palette.
local loaded_palette = require("palette")
local server_palette = type(loaded_palette) == "table" and loaded_palette or assert(Palette, "Paleta Lupi ausente")
local logical_colors = require("lupix_colors")
local hardware_ui = ui
local remap = {[0] = 0}
local function drawing_color(index)
  assert(type(index) == "number" and index % 1 == 0 and logical_colors[index + 1] ~= nil, "Indice de cor invalido")
  if remap[index] ~= nil then return remap[index] end
  local color = logical_colors[index + 1]
  for position = 2, #server_palette do
    if server_palette[position] == color then remap[index] = position - 1; return position - 1 end
  end
  assert(#server_palette < 256, "Paleta Lupi cheia")
  local position = #server_palette
  server_palette[position + 1] = color
  hardware_ui.palset(position, color)
  remap[index] = position
  return position
end
ui = setmetatable({
  cls = function(color) return hardware_ui.cls(drawing_color(color)) end,
  print = function(text, x, y, color) return hardware_ui.print(text, x, y, drawing_color(color)) end,
  draw_rect = hardware_ui.draw_rect and function(x,y,w,h,filled,color) return hardware_ui.draw_rect(x,y,w,h,filled,drawing_color(color)) end or nil,
  rectfill = hardware_ui.rectfill and function(x1,y1,x2,y2,color) return hardware_ui.rectfill(x1,y1,x2,y2,drawing_color(color)) end or nil,
}, {__index = hardware_ui})
local Runtime, boot_error
local ok, result = pcall(function()
  local runtime = require "lupix_runtime"
  local scene = require("lupix_scenes.Main")
  local entry = require "lupix_entry"
  runtime.start(scene, entry, "scenes/Main.scene.json")
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
