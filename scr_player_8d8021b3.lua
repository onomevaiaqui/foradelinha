local update, draw, on_ready, on_scene_enter, on_scene_exit
local velocidade_y = 0
local velocidade_andar = 1.5
local velocidade_correr = 2.7
local gravidade = 0.28
local impulso_pulo = -5.5

local function bloqueado(x, y, largura, altura)
    return world.solid_at(x + 1, y + 1)
        or world.solid_at(x + largura - 2, y + 1)
        or world.solid_at(x + 1, y + altura - 1)
        or world.solid_at(x + largura - 2, y + altura - 1)
end

local function no_chao(x, y, largura, altura)
    return world.solid_at(x + 2, y + altura + 1)
        or world.solid_at(x + largura - 3, y + altura + 1)
end

update = function(frame, player)
    if not player then return end

    local x, y = player.x, player.y
    local largura, altura = player.width, player.height
    local eixo = 0

    if input.down("move_left") then eixo = eixo - 1 end
    if input.down("move_right") then eixo = eixo + 1 end

    local velocidade = velocidade_andar
    if input.down("run") then velocidade = velocidade_correr end

    local novo_x = x + eixo * velocidade
    if not bloqueado(novo_x, y, largura, altura) then
        x = novo_x
    end

    local apoiado = no_chao(x, y, largura, altura)
    if apoiado and velocidade_y > 0 then
        velocidade_y = 0
    end

    if apoiado and input.pressed("jump") then
        velocidade_y = impulso_pulo
    else
        velocidade_y = math.min(velocidade_y + gravidade, 6)
    end

    local novo_y = y + velocidade_y
    if bloqueado(x, novo_y, largura, altura) then
        velocidade_y = 0
    else
        y = novo_y
    end

    world.move(player, x, y)
end
return { update = update, draw = draw, on_ready = on_ready, on_scene_enter = on_scene_enter, on_scene_exit = on_scene_exit }
