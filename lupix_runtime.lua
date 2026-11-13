require "sprites"
local Scene = require "lupix_scene"
local Runtime = {}
local current_scene, entry_script, transition_data
local frame_scripts = {}
local camera_x, camera_y = 0, 0
local diagnostic_frame_logged = false
local diagnostic_draw_logged = false
local diagnostic_map_calls, diagnostic_sprite_hits = 0, 0
local function diagnostic_log(message)
  if ui and type(ui.log) == "function" then pcall(ui.log, "[LUPIX] " .. tostring(message)) end
end
world = { entities = {}, maps = {} }
input = {}
animation = {}
camera = {}
scene = {}
local actions = {
  ["move_left"] = { 4, },
  ["move_right"] = { 2, },
  ["move_up"] = { 1, },
  ["move_down"] = { 3, },
  ["jump"] = { 7, },
  ["dash"] = { 8, },
  ["interact"] = { 6, },
  ["pause"] = { 14, },
}
local animation_sets = {
  ["animations/player_anim.animations.json"] = require("anm_player__90ad80bf"),
}
local scenes = {
  ["scenes/Main.scene.json"] = require("scn_main_e5d44358"),
}

local function find_sprite(path)
  local value = Sprites
  for part in string.gmatch((path or ""):gsub("\\\\", "/"), "[^/]+") do
    if type(value) ~= "table" then return nil end
    value = value[part]
  end
  return value
end
local function action_down(name, pressed)
  local list = actions[name]
  if not list then return false end
  for _, button in ipairs(list) do
    if (pressed and ui.btnp(button)) or (not pressed and ui.btn(button)) then return true end
  end
  return false
end
function input.down(name) return action_down(name, false) end
function input.pressed(name) return action_down(name, true) end
function camera.set(x, y)
  camera_x, camera_y = x or 0, y or 0
  ui.camera(camera_x, camera_y)
end
ui.sprite = function(path, x, y, flip)
  local sprite = find_sprite(path)
  if sprite then ui.spr(sprite, x, y, flip or false) end
end
ui.sprite_region = function(path, sx, sy, sw, sh, x, y, w, h, flip)
  local sprite = find_sprite(path)
  if sprite then ui.spr(sprite, x, y, flip or false) end
end
function animation.frame(resource, clip_name, index)
  local set = animation_sets[(resource or ""):gsub("\\\\", "/")]
  local clip = set and set.clips and set.clips[clip_name]
  local frame = clip and clip.frames and clip.frames[index]
  if not frame then return nil end
  return { sprite = frame.sprite, x = frame.export_x, y = frame.export_y,
    width = frame.width, height = frame.height, offset_x = frame.offset_x,
    offset_y = frame.offset_y, frame_width = clip.frame_width,
    frame_height = clip.frame_height, fps = clip.fps, loop = clip.loop, index = index }
end
local function setup_world(scene)
  world.entities, world.maps, frame_scripts = scene.entities or {}, {}, {}
  for _, entity in ipairs(world.entities) do
    if entity.tilemap then
      world.maps[#world.maps + 1] = { data = entity.tilemap, x = entity.x or 0, y = entity.y or 0 }
    end
    for _, component in ipairs(entity.components or {}) do
      if component.script then frame_scripts[#frame_scripts + 1] = { entity = entity, script = component.script } end
    end
  end
end
function scene.current() return current_scene end
function scene.take_data()
  local data = transition_data
  transition_data = nil
  return data
end
function scene.change(path, data)
  if type(path) ~= "string" then error("scene.change espera o caminho relativo de uma cena") end
  if data ~= nil and type(data) ~= "table" then error("scene.change espera dados de transição em uma tabela Lua") end
  path = path:gsub("\\\\", "/")
  local next_scene = scenes[path]
  if not next_scene then error("cena não exportada ou inexistente: " .. path) end
  if path == current_scene then return false end
  local previous_scene = current_scene
  if entry_script and type(entry_script.on_scene_exit) == "function" then entry_script.on_scene_exit(path) end
  current_scene = path
  setup_world(next_scene)
  transition_data = data
  if entry_script and type(entry_script.on_scene_enter) == "function" then entry_script.on_scene_enter(previous_scene, data) end
  return true
end
local function map_cell(map, x, y)
  local meta = map.data and map.data.metadata
  if not meta or meta.tile_size <= 0 then return nil end
  local col, row = math.floor((x - map.x) / meta.tile_size), math.floor((y - map.y) / meta.tile_size)
  if col < 0 or row < 0 or col >= meta.width or row >= meta.height then return nil end
  return row * meta.width + col + 1
end
function world.find(name_or_id)
  for _, entity in ipairs(world.entities) do
    if entity.id == name_or_id or entity.name == name_or_id then return entity end
  end
  return nil
end
function world.move(entity, x, y)
  if type(entity) == "string" then entity = world.find(entity) end
  if type(entity) ~= "table" or type(x) ~= "number" or type(y) ~= "number" then error("world.move espera entidade/nome e coordenadas x,y") end
  entity.x, entity.y = x, y
end
function world.overlap(a, b)
  if type(a) == "string" then a = world.find(a) end
  if type(b) == "string" then b = world.find(b) end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  return (a.x or 0) < (b.x or 0) + (b.width or 0) and (b.x or 0) < (a.x or 0) + (a.width or 0)
    and (a.y or 0) < (b.y or 0) + (b.height or 0) and (b.y or 0) < (a.y or 0) + (a.height or 0)
end
function world.solid_at(x, y)
  for _, map in ipairs(world.maps) do local index = map_cell(map, x, y); if index and map.data.collision[index] then return true end end
  return false
end
function world.area_at(x, y, area_name)
  local wanted = string.lower(tostring(area_name or ""))
  for _, map in ipairs(world.maps) do
    local index = map_cell(map, x, y)
    if index and string.lower(tostring(map.data.areas[index] or "")) == wanted then return true end
  end
  return false
end
local function draw_scene()
  local trace_frame = not diagnostic_draw_logged
  diagnostic_map_calls, diagnostic_sprite_hits = 0, 0
  if trace_frame then diagnostic_log("draw_scene begin entities=" .. tostring(#world.entities)) end
  for _, entity in ipairs(world.entities) do
    if entity.visible ~= false then
      if entity.tilemap then
        for _, layer in ipairs(entity.tilemap.layer_order or {}) do
          local data = entity.tilemap[layer.name]
          if data then
            diagnostic_map_calls = diagnostic_map_calls + 1
            if trace_frame then diagnostic_log("map call entity=" .. tostring(entity.name) .. " layer=" .. tostring(layer.name)) end
            ui.map(data, entity.x or 0, entity.y or 0)
          end
        end
      end
      local animated, animation_set, script_draws = false, nil, false
      for _, component in ipairs(entity.components or {}) do
        if component.type == "Animação" then
          animated = true
          animation_set = component.animations
        end
        if component.script then script_draws = true end
      end
      if entity.sprite and not animated and not script_draws then
        local sprite = find_sprite(entity.sprite)
        if trace_frame then diagnostic_log("sprite draw entity=" .. tostring(entity.name) .. " found=" .. tostring(sprite ~= nil)) end
        if sprite then diagnostic_sprite_hits = diagnostic_sprite_hits + 1; ui.spr(sprite, entity.x or 0, entity.y or 0, false) end
      elseif animated and not script_draws then
        -- Match the editor's static pose preview: when an entity
        -- has animation metadata but no Lua drawing script yet,
        -- keep its first pose visible instead of hiding the sprite.
        -- Playback and state selection remain the user's Lua code.
        local clip_name = animation_set and animation_set.default_clip
        local clip = clip_name and animation_set.clips and animation_set.clips[clip_name]
        local frame = clip and clip.frames and clip.frames[1]
        local sprite = frame and find_sprite(frame.sprite)
        if trace_frame then diagnostic_log("animation pose entity=" .. tostring(entity.name) .. " clip=" .. tostring(clip_name) .. " found=" .. tostring(sprite ~= nil)) end
        if sprite then
          diagnostic_sprite_hits = diagnostic_sprite_hits + 1
          ui.spr(sprite, (entity.x or 0) + (frame.offset_x or 0),
            (entity.y or 0) + (frame.offset_y or 0), false)
        elseif entity.sprite then
          sprite = find_sprite(entity.sprite)
          if sprite then diagnostic_sprite_hits = diagnostic_sprite_hits + 1; ui.spr(sprite, entity.x or 0, entity.y or 0, false) end
        end
      end
    end
  end
  if trace_frame then diagnostic_log("draw_scene end"); diagnostic_draw_logged = true end
end
function Runtime.start(initial_scene, entry, initial_scene_path)
  entry_script = entry or {}
  current_scene = initial_scene_path
  setup_world(initial_scene)
  diagnostic_log("runtime start scene=" .. tostring(current_scene) .. " entities=" .. tostring(#world.entities) .. " maps=" .. tostring(#world.maps))
  for _, entity in ipairs(world.entities) do
    if entity.sprite then
      local sprite = find_sprite(entity.sprite)
      diagnostic_log("sprite entity=" .. tostring(entity.name) .. " found=" .. tostring(sprite ~= nil) ..
        " path=" .. tostring(entity.sprite) .. (sprite and (" size=" .. tostring(sprite.width) .. "x" .. tostring(sprite.height)) or ""))
    end
    if entity.tilemap then
      diagnostic_log("tilemap entity=" .. tostring(entity.name) .. " layers=" .. tostring(#(entity.tilemap.layer_order or {})))
    end
  end
end
function Runtime.update(frame)
  if not diagnostic_frame_logged then diagnostic_log("first update frame=" .. tostring(frame)); diagnostic_frame_logged = true end
  local drew_scene = false
  local native_cls = ui.cls
  ui.cls = function(color)
    if drew_scene then return end
    native_cls(color or 0)
    draw_scene()
    drew_scene = true
  end
  local ok, err = pcall(function()
    if entry_script and type(entry_script.update) == "function" then entry_script.update(frame) end
    for _, behavior in ipairs(frame_scripts) do
      if behavior.script and type(behavior.script.update) == "function" then behavior.script.update(frame, behavior.entity) end
    end
    if not drew_scene then native_cls(0); draw_scene() end
  end)
  ui.cls = native_cls
  if not ok then diagnostic_log("update erro: " .. tostring(err)); error(err) end
end
function Runtime.status()
  return { draw = diagnostic_draw_logged, maps = diagnostic_map_calls, sprites = diagnostic_sprite_hits }
end
function Runtime.draw_sprite_probe()
  ui.camera()
  ui.cls(0)
  local found, entities = 0, 0
  for _, entity in ipairs(world.entities) do
    if entity.visible ~= false then
      local path = entity.sprite
      local offset_x, offset_y = 0, 0
      for _, component in ipairs(entity.components or {}) do
        if component.type == "Animação" then
          local set = component.animations
          local clip_name = set and set.default_clip
          local clip = clip_name and set.clips and set.clips[clip_name]
          local frame = clip and clip.frames and clip.frames[1]
          if frame then path, offset_x, offset_y = frame.sprite, frame.offset_x or 0, frame.offset_y or 0 end
        end
      end
      if path then
        entities = entities + 1
        local sprite = find_sprite(path)
        if sprite then
          found = found + 1
          ui.spr(sprite, (entity.x or 0) + offset_x, (entity.y or 0) + offset_y, false)
        end
      end
    end
  end
  return { found = found, entities = entities }
end
return Runtime