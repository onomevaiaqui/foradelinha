local M = {}
local metadata = { width = 30, height = 16, tile_size = 16 }
M.layer_order = {
  { name = "Ground", order = 0 },
}
M["Ground"] = { ["lx_121302fc7d6c"] = { [345] = 3, [346] = 31, [375] = 17, [405] = 17, [421] = 31, [422] = 31, [423] = 31, [424] = 31, [425] = 31, [426] = 31, [427] = 31, [428] = 31, [429] = 31, [430] = 31, [431] = 31, [432] = 31, [433] = 31, [434] = 31, [435] = 32, }, metadata = metadata, lupi_metadata = metadata }
M.metadata = metadata
M.lupi_metadata = metadata
M.tilesets = {}
M.collision = { [421] = true, [422] = true, [423] = true, [424] = true, [425] = true, [426] = true, [427] = true, [428] = true, [429] = true, [430] = true, [431] = true, [432] = true, [433] = true, [434] = true, }
M.areas = { }
return M
