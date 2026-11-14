local M = { name = "Main", entities = {
  { id = "23312baf3a6144d5b311a7ae388a8506", name = "Cenario", kind = "Entity", parent = nil, x = 0, y = 0, width = 480, height = 256, order = 0, visible = true, parallax_x = 1, parallax_y = 1, tilemap = require("map_cenario_9c952265"), components = { { type = "TileMap", resource = "maps/CenarioMap.tilemap.json" }, } },
  { id = "90622112ff0d48b5a1f58d44ec3a33f8", name = "Player", kind = "Entity", parent = nil, x = 17.129, y = 96.188, width = 16, height = 16, order = 0, visible = true, parallax_x = 1, parallax_y = 1, sprite = "sprites/lx_5392001c1775", components = { { type = "Sprite", resource = "sprites/lx_5392001c1775" }, { type = "Animação", animations = require("anm_player__10347491") }, { type = "Script Lua", script = require("scr_player_8d8021b3") }, } },
} }
return M
