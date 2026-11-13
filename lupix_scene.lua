require "sprites"
local Scene = {}
local function sprite(path)
  local value = Sprites
  for part in string.gmatch(path or "", "[^/]+") do
    if type(value) ~= "table" then return nil end
    value = value[part]
  end
  return value
end
function Scene.draw(scene, camera_x, camera_y)
  camera_x, camera_y = camera_x or 0, camera_y or 0
  for _, entity in ipairs(scene.entities or {}) do
    if entity.visible ~= false then
      ui.camera(math.floor(camera_x * (entity.parallax_x or 1)),
        math.floor(camera_y * (entity.parallax_y or 1)))
      if entity.tilemap then
        for _, layer in ipairs(entity.tilemap.layer_order or {}) do
          ui.map(entity.tilemap[layer.name], entity.x, entity.y)
        end
      end
      if entity.sprite then
        local ref = sprite(entity.sprite)
        if ref then ui.spr(ref, entity.x, entity.y) end
      end
    end
  end
  ui.camera(camera_x, camera_y)
end
function Scene.cell_index(map, x, y, origin_x, origin_y)
  local m = map and map.metadata
  if not m or m.tile_size <= 0 then return nil end
  local col = math.floor((x - (origin_x or 0)) / m.tile_size)
  local row = math.floor((y - (origin_y or 0)) / m.tile_size)
  if col < 0 or row < 0 or col >= m.width or row >= m.height then return nil end
  return row * m.width + col + 1
end
function Scene.solid_at(map, x, y, origin_x, origin_y)
  local index = Scene.cell_index(map, x, y, origin_x, origin_y)
  return index ~= nil and map.collision[index] == true or false
end
function Scene.area_at(map, x, y, origin_x, origin_y)
  local index = Scene.cell_index(map, x, y, origin_x, origin_y)
  return index and map.areas[index] or nil
end
function Scene.instantiate(prefab, x, y, id_prefix)
  local result, ids = {}, {}
  x, y, id_prefix = x or 0, y or 0, id_prefix or "instance_"
  for _, entity in ipairs(prefab.entities or {}) do ids[entity.id] = id_prefix .. tostring(entity.id) end
  for _, entity in ipairs(prefab.entities or {}) do
    local copy = {}
    for key, value in pairs(entity) do copy[key] = value end
    copy.id = ids[entity.id]
    copy.parent = entity.parent and ids[entity.parent] or nil
    if not entity.parent then copy.x, copy.y = (entity.x or 0) + x, (entity.y or 0) + y end
    result[#result + 1] = copy
  end
  return result
end
return Scene