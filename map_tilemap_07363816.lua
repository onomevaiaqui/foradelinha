local M = {}
local metadata = { width = 30, height = 16, tile_size = 16 }
M.layer_order = {
  { name = "Ground", order = 0 },
}
M["Ground"] = { tileset = { }, metadata = metadata, tilesets = { tileset = "tiles" } }
M.metadata = metadata
M.tilesets = {}
M.collision = { }
M.areas = { }
return M
