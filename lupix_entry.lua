local update, draw, on_ready, on_scene_enter, on_scene_exit
local ANIMATION_RESOURCE = "animations/player_anim.animations.json"

local SCREEN_WIDTH = 480
local WALK_SPEED = 1.5
local RUN_SPEED = 2.4
local CLIMB_SPEED = 1.2
local JUMP_SPEED = -5.5
local GRAVITY = 0.28
local MAX_FALL_SPEED = 6

-- Atualize as contagens quando criar os clipes no editor de animação.
local CLIP_COUNTS = {
    idle = 5,
    run = 8,
    jump = 1,
    fall = 1,
    climb = 1
}

local state = {
    vy = 0,
    climbing = false,
    facing = 1,
    animation = nil,
    animation_start = 0
}

local function blocked(x, y, width, height)
    return world.solid_at(x + 1, y + 1)
        or world.solid_at(x + width - 1, y + 1)
        or world.solid_at(x + 1, y + height - 1)
        or world.solid_at(x + width - 1, y + height - 1)
end

local function on_ground(x, y, width, height)
    return world.solid_at(x + 1, y + height + 1)
        or world.solid_at(x + width - 1, y + height + 1)
end

local function move_axis(x, y, amount, horizontal, width, height)
    local steps = math.max(1, math.ceil(math.abs(amount)))
    local step = amount / steps

    for _ = 1, steps do
        local next_x = x
        local next_y = y

        if horizontal then
            next_x = x + step
        else
            next_y = y + step
        end

        if blocked(next_x, next_y, width, height) then
            return x, y, true
        end

        x = next_x
        y = next_y
    end

    return x, y, false
end

local function level_width()
    local right_edge = SCREEN_WIDTH

    for _, map in ipairs(world.maps or {}) do
        local metadata = map.data and map.data.metadata
        if metadata and metadata.width then
            local tile_size = metadata.tile_size or 16
            local map_right = (map.x or 0) + metadata.width * tile_size
            right_edge = math.max(right_edge, map_right)
        end
    end

    return right_edge
end

local function get_animation_pose(name, frame_number)
    local tried = {}

    -- Se um clipe ainda não existe, usa idle ou run como referência temporária.
    local candidates = { name, "idle", "run" }

    for _, clip_name in ipairs(candidates) do
        if not tried[clip_name] then
            tried[clip_name] = true

            local count = CLIP_COUNTS[clip_name] or 1
            local first_pose = animation.frame(
                ANIMATION_RESOURCE,
                clip_name,
                1
            )

            if first_pose then
                local fps = first_pose.fps or 8

                if state.animation ~= clip_name then
                    state.animation = clip_name
                    state.animation_start = frame_number
                end

                local elapsed = math.max(0, frame_number - state.animation_start)
                local frame_offset = math.floor(elapsed * fps / 60)
                local index

                if first_pose.loop == false then
                    index = math.min(frame_offset + 1, count)
                else
                    index = (frame_offset % count) + 1
                end

                return animation.frame(
                    ANIMATION_RESOURCE,
                    clip_name,
                    index
                ) or first_pose
            end
        end
    end

    return nil
end

update = function(frame_number, player)
    player = player or world.find("Player") or world.find("player")
    if not player then
        return
    end

    frame_number = frame_number or 0

    local x = player.x or 0
    local y = player.y or 0
    local width = player.width or 16
    local height = player.height or 16

    local left = input.down("move_left")
    local right = input.down("move_right")
    local up = input.down("move_up")
    local down = input.down("move_down")

    local horizontal = 0
    if left then horizontal = horizontal - 1 end
    if right then horizontal = horizontal + 1 end

    if horizontal ~= 0 then
        state.facing = horizontal
    end

    local speed = WALK_SPEED
    if input.down("run") then
        speed = RUN_SPEED
    end

    x, y = move_axis(
        x,
        y,
        horizontal * speed,
        true,
        width,
        height
    )

    local center_x = x + width / 2
    local center_y = y + height / 2
    local on_ladder = world.area_at(center_x, center_y, "Ladder")

    if on_ladder and (up or down) then
        state.climbing = true
    end

    if state.climbing and on_ladder then
        state.vy = 0

        local vertical = 0
        if up then vertical = vertical - CLIMB_SPEED end
        if down then vertical = vertical + CLIMB_SPEED end

        x, y = move_axis(
            x,
            y,
            vertical,
            false,
            width,
            height
        )

        if input.pressed("jump") then
            state.climbing = false
            state.vy = JUMP_SPEED
        end
    else
        state.climbing = false

        local grounded = on_ground(x, y, width, height)

        if grounded and state.vy > 0 then
            state.vy = 0
        end

        if grounded and input.pressed("jump") then
            state.vy = JUMP_SPEED
        end

        state.vy = math.min(state.vy + GRAVITY, MAX_FALL_SPEED)

        local old_y = y
        x, y, _ = move_axis(
            x,
            y,
            state.vy,
            false,
            width,
            height
        )

        if y == old_y and state.vy > 0 then
            state.vy = 0
        end
    end

    world.move(player, x, y)

    local animation_name
    if state.climbing then
        animation_name = "climb"
    elseif state.vy < 0 then
        animation_name = "jump"
    elseif state.vy > 0 and not on_ground(x, y, width, height) then
        animation_name = "fall"
    elseif horizontal ~= 0 then
        animation_name = "run"
    else
        animation_name = "idle"
    end

    local camera_x = math.max(
        0,
        math.min(x - 232, level_width() - SCREEN_WIDTH)
    )

    camera.set(camera_x, 0)

    -- A primeira chamada a cls desenha a cena; depois desenhamos o Player.
    ui.cls(0)

    local pose = get_animation_pose(animation_name, frame_number)
    if pose then
        ui.sprite_region(
            pose.sprite,
            pose.x or 0,
            pose.y or 0,
            pose.width or width,
            pose.height or height,
            x + (pose.offset_x or 0),
            y + (pose.offset_y or 0),
            pose.width or width,
            pose.height or height,
            state.facing < 0
        )
    end
end
return { update = update, draw = draw, on_ready = on_ready, on_scene_enter = on_scene_enter, on_scene_exit = on_scene_exit }
