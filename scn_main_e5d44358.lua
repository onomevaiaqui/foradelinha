local M = { name = "Main", entities = {
  { id = "4648e5d22002475f944c5c09af973479", name = "TileMap", kind = "Entity", parent = nil, x = 0, y = 0, width = 480, height = 256, order = 0, visible = true, parallax_x = 1, parallax_y = 1, tilemap = require("map_tilemap_07363816"), components = { { type = "TileMap", resource = "maps/TileMapMap.tilemap.json" }, } },
  { id = "90ba22dd1f1a4ff9bcc0aa3f3eed2259", name = "player", kind = "Entity", parent = nil, x = 65, y = 208, width = 16, height = 16, order = 0, visible = true, parallax_x = 1, parallax_y = 1, sprite = "sprites/lx_8543cc84aa22", components = { { type = "Sprite", resource = "sprites/lx_8543cc84aa22" }, { type = "Animação", animations = require("anm_player__90ad80bf") }, { type = "Script Lua", script = require("scr_player_8d8021b3") }, } },
} }
return M
