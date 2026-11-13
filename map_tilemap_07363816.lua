local M = {}
local metadata = { width = 30, height = 16, tile_size = 16 }
M.layer_order = {
  { name = "Ground", order = 0 },
  { name = "ladder", order = 1 },
}
M["Ground"] = { tileset = { [345] = 3, [346] = 31, [347] = 31, [348] = 31, [349] = 31, [350] = 31, [351] = 31, [352] = 31, [353] = 31, [354] = 31, [355] = 31, [356] = 31, [357] = 31, [358] = 31, [359] = 31, [360] = 4, [375] = 17, [390] = 15, [405] = 17, [420] = 15, [421] = 31, [422] = 31, [423] = 31, [424] = 31, [425] = 31, [426] = 31, [427] = 31, [428] = 31, [429] = 31, [430] = 31, [431] = 31, [432] = 31, [433] = 31, [434] = 31, [435] = 32, [450] = 15, [467] = 1, [468] = 1, [469] = 1, [470] = 1, [471] = 1, [472] = 1, [473] = 1, [474] = 1, [475] = 1, [476] = 1, [477] = 1, [478] = 1, [479] = 1, [480] = 19, }, metadata = metadata, lupi_metadata = metadata, tilesets = { tileset = "lx_121302fc7d6c" } }
M["ladder"] = { tileset = { [314] = 0, [344] = 1, [374] = 1, [404] = 1, }, metadata = metadata, lupi_metadata = metadata, tilesets = { tileset = "lx_55937a7ebfcf" } }
M.metadata = metadata
M.lupi_metadata = metadata
M.tilesets = {}
M.collision = { [345] = true, [346] = true, [347] = true, [348] = true, [349] = true, [350] = true, [351] = true, [352] = true, [353] = true, [354] = true, [355] = true, [356] = true, [357] = true, [358] = true, [359] = true, [360] = true, [375] = true, [405] = true, [421] = true, [422] = true, [423] = true, [424] = true, [425] = true, [426] = true, [427] = true, [428] = true, [429] = true, [430] = true, [431] = true, [432] = true, [433] = true, [434] = true, [435] = true, }
M.areas = { [314] = "Ladder", [344] = "Ladder", [374] = "Ladder", [404] = "Ladder", }
return M
