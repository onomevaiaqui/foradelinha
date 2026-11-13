-- Lupi assigns palette indices while processing the PNG sources.
-- Keep the editor's logical colors stable without replacing that palette.
local loaded_palette = require("palette")
local server_palette = type(loaded_palette) == "table" and loaded_palette or assert(Palette, "Paleta Lupi ausente")
local logical_colors = {  0x0000,
  0x2D07,
  0x20A5,
  0x1021,
  0x1842,
  0x2AAA,
  0x2605,
  0x1D02,
  0x1881,
  0x3351,
  0x562E,
  0x28C5,
  0x6AF4,
  0x3D48,
  0x1862,
  0x6739,
  0x7BDE,
  0x56B5,
  0x4631,
  0x19DB,
  0x52FA,
  0x677D,
  0x4655,
  0x31AF,
  0x2F93,
}
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
  local scene = require("scn_main_e5d44358")
  local entry = require "lupix_entry"
  runtime.start(scene, entry, "scenes/Main.scene.json")
  return runtime
end)
if ok then Runtime = result else boot_error = tostring(result) end
local function show_error(message)
  if type(hardware_ui.log) == "function" then hardware_ui.log("[LUPIX] erro: " .. tostring(message or "desconhecido")) end
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
local function restore_palette()
  for position = 1, #server_palette do
    local color = server_palette[position]
    if type(color) == "number" then hardware_ui.palset(position - 1, color) end
  end
end
function update(frame)
  restore_palette()
  if boot_error then show_error(boot_error); return end
  local update_ok, update_error = pcall(function() Runtime.update(frame) end)
  if not update_ok then show_error(update_error); return end
end
