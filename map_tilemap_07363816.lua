local M = {}
local metadata = { width = 30, height = 16, tile_size = 16 }
M.layer_order = {
  { name = "Ground", order = 0 },
}
M["Ground"] = { ["lx_121302fc7d6c"] = { [421] = 60, [422] = 61, [423] = 61, [424] = 61, [425] = 61, [426] = 61, [427] = 61, [428] = 61, [429] = 61, [430] = 61, [431] = 61, [432] = 61, [433] = 61, [434] = 62, }, metadata = metadata, lupi_metadata = metadata }
M.metadata = metadata
M.lupi_metadata = metadata
M.tilesets = {}
M.collision = { [421] = true, [422] = true, [423] = true, [424] = true, [425] = true, [426] = true, [427] = true, [428] = true, [429] = true, [430] = true, [431] = true, [432] = true, [433] = true, [434] = true, }
M.areas = { }
return M
