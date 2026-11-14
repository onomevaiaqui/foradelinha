local update, draw, on_ready, on_scene_enter, on_scene_exit
local velocidade_y = 0
local velocidade_andar = 1.5
local velocidade_correr = 2.7
local velocidade_escada = 1.5
local gravidade = 0.38
local impulso_pulo = -4
local tamanho_tile = 16

local recurso_animacao = "animations/Player_anim.animations.json"
local quadros_por_animacao = {
    idle = 5,
    run = 8,
    jump = 2,
    climb = 8
}

local animacao_atual = "idle"
local quadro_atual = 1
local ticks_no_quadro = 0
local direcao = 1
local na_escada = false

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

local function dentro_da_escada(x, y, largura, altura)
    local centro_x = x + largura / 2

    return world.area_at(centro_x, y + 1, "Ladder")
        or world.area_at(centro_x, y + altura / 2, "Ladder")
        or world.area_at(centro_x, y + altura - 1, "Ladder")
        or world.area_at(centro_x, y + altura, "Ladder")
end

local function escolher_animacao(nome)
    if nome ~= animacao_atual then
        animacao_atual = nome
        quadro_atual = 1
        ticks_no_quadro = 0
    end
end

update = function(frame, player)
    if not player then return end

    local x, y = player.x, player.y
    local x_inicial = x
    local largura, altura = player.width, player.height

    local eixo_x = 0
    if input.down("move_left") then
        eixo_x = eixo_x - 1
        direcao = -1
    end
    if input.down("move_right") then
        eixo_x = eixo_x + 1
        direcao = 1
    end

    local subir = input.down("move_up")
    local descer = input.down("move_down")
    local animacao_escada_movendo = false
    local pulou = false

    -- O comando lateral solta o personagem da escada.
    if na_escada and eixo_x ~= 0 then
        na_escada = false
    end

    -- Sobe na escada ao pressionar cima ou baixo dentro da área pintada.
    if not na_escada
        and eixo_x == 0
        and (subir or descer)
        and dentro_da_escada(x, y, largura, altura)
    then
        na_escada = true
        velocidade_y = 0

        -- Centraliza o personagem no tile da escada.
        local centro_x = x + largura / 2
        local coluna_escada = math.floor(centro_x / tamanho_tile)
        local novo_x = coluna_escada * tamanho_tile

        if not bloqueado(novo_x, y, largura, altura) then
            x = novo_x
        end
    end

    if na_escada and input.pressed("jump") then
        na_escada = false
        velocidade_y = impulso_pulo
        pulou = true
    end

    if na_escada then
        velocidade_y = 0

        local deslocamento_y = 0
        if subir and not descer then
            deslocamento_y = -velocidade_escada
        elseif descer and not subir then
            deslocamento_y = velocidade_escada
        end

        if deslocamento_y ~= 0 then
            local destino_y = y + deslocamento_y

            if dentro_da_escada(x, destino_y, largura, altura)
                and not bloqueado(x, destino_y, largura, altura)
            then
                y = destino_y
                animacao_escada_movendo = true
            elseif deslocamento_y > 0
                and not bloqueado(x, destino_y, largura, altura)
            then
                -- Ao descer pelo fim da escada, solta e volta à gravidade normal.
                y = destino_y
                na_escada = false
            end
            -- No topo, não passa do fim da área. Pode sair pelo lado.
        end
    end

    if not na_escada then
        local velocidade = velocidade_andar
        if input.down("run") then
            velocidade = velocidade_correr
        end

        local novo_x = x + eixo_x * velocidade
        if not bloqueado(novo_x, y, largura, altura) then
            x = novo_x
        end

        local apoiado = no_chao(x, y, largura, altura)
        if apoiado and velocidade_y > 0 then
            velocidade_y = 0
        end

        if not pulou and apoiado and input.pressed("jump") then
            velocidade_y = impulso_pulo
            apoiado = false
        elseif not pulou then
            velocidade_y = math.min(velocidade_y + gravidade, 6)
        end

        local novo_y = y + velocidade_y
        if bloqueado(x, novo_y, largura, altura) then
            velocidade_y = 0
        else
            y = novo_y
        end
    end

    world.move(player, x, y)

    if na_escada then
        escolher_animacao("climb")
    elseif velocidade_y ~= 0 then
        escolher_animacao("jump")
    elseif x ~= x_inicial then
        escolher_animacao("run")
    else
        escolher_animacao("idle")
    end

    -- Enquanto parado na escada, mantém o quadro atual.
    if animacao_atual ~= "climb" or animacao_escada_movendo then
        local primeiro_quadro = animation.frame(
            recurso_animacao,
            animacao_atual,
            1
        )

        local fps = primeiro_quadro and primeiro_quadro.fps or 8
        local intervalo = math.max(1, math.floor(60 / fps + 0.5))

        ticks_no_quadro = ticks_no_quadro + 1
        if ticks_no_quadro >= intervalo then
            ticks_no_quadro = 0

            local total = quadros_por_animacao[animacao_atual] or 1
            quadro_atual = quadro_atual + 1
            if quadro_atual > total then
                quadro_atual = 1
            end
        end
    end
end

draw = function(frame, player)
    if not player then return end

    local pose = animation.frame(
        recurso_animacao,
        animacao_atual,
        quadro_atual
    )

    if not pose then return end

    ui.sprite_region(
        pose.sprite,
        pose.x,
        pose.y,
        pose.width,
        pose.height,
        player.x + (pose.offset_x or 0),
        player.y + (pose.offset_y or 0),
        pose.width,
        pose.height,
        direcao < 0
    )
end
return { update = update, draw = draw, on_ready = on_ready, on_scene_enter = on_scene_enter, on_scene_exit = on_scene_exit }
