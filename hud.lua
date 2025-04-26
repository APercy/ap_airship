ap_airship.hud_list = {}

function ap_airship.get_pointer_angle(value, maxvalue)
    local angle = value/maxvalue * 180
    --angle = angle - 90
    --angle = angle * -1
    return angle
end

function ap_airship.animate_gauge(player, ids, prefix, x, y, angle)
    local angle_in_rad = math.rad(angle + 180)
    local dim = 10
    local pos_x = math.sin(angle_in_rad) * dim
    local pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "2"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 20
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "3"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 30
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "4"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 40
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "5"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 50
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "6"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 60
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "7"], "offset", {x = pos_x + x, y = pos_y + y})
end

local hud_panel_x = 10      -- HUD left offset
local hud_panel_y = -10     -- HUD bottom offset

-- Ground speed indicator
-- left bottom corner
local gs_ind_x = hud_panel_x
local gs_ind_y = hud_panel_y
-- zero position
local gs_ind_zero_x = gs_ind_x + 83
local gs_ind_zero_y = gs_ind_y - 42
-- indicator range
local gs_ind_range_xmin = gs_ind_zero_x - 56
local gs_ind_range_xmax = gs_ind_zero_x + 58
local gs_ind_xstep = 57 / 4
local gs_ind_range_ymax = gs_ind_y - 154
local gs_ind_range_ymin = gs_ind_y - 13
local gs_ind_ystep = math.abs(gs_ind_range_ymax - gs_ind_zero_y) / 8

local function bound(min, value, max)
    return math.max(math.min(value, max), min)
end

local function set_gs_indicator(player, ids, forward, right)
    player:hud_change(
        ids["gs_hor"],
        "offset",
        {
            x = gs_ind_x,
            y = gs_ind_zero_y - bound(-2, forward, 8) * gs_ind_ystep
        }
    )
    player:hud_change(
        ids["gs_vert"],
        "offset",
        {
            x = gs_ind_zero_x + bound(-4, right, 4) * gs_ind_xstep,
            y = gs_ind_y
        }
    )
end

function ap_airship.update_hud(self, coal, water, pressure, power_lever)
    local player = minetest.get_player_by_name(self.driver_name)
    if player == nil then return end
    local player_name = player:get_player_name()

    local screen_pos_y = -100
    local screen_pos_x = 10

    local water_gauge_x = screen_pos_x + 374
    local water_gauge_y = screen_pos_y
    local press_gauge_x = screen_pos_x + 85
    local press_gauge_y = water_gauge_y
    local coal_1_x = screen_pos_x + 182
    local coal_1_y = screen_pos_y
    local coal_2_x = coal_1_x + 60
    local coal_2_y = screen_pos_y
    local throttle_x = screen_pos_x + 395
    local throttle_y = screen_pos_y + 45

    local ids = ap_airship.hud_list[player_name]
    if ids then
        player:hud_change(ids["throttle"], "offset", {x = throttle_x, y = throttle_y - power_lever})

        local yaw = self.object:get_rotation().y
        local velocity = self.object:get_velocity()
        local sin_yaw = math.sin(yaw)
        local cos_yaw = math.cos(yaw)

        set_gs_indicator(
            player,
            ids,
            velocity.z * cos_yaw - velocity.x * sin_yaw,
            velocity.z * sin_yaw + velocity.x * cos_yaw
        )

        --[[local coal_value = coal
        if coal_value > 99 then coal_value = 99 end
        if coal_value < 0 then coal_value = 0 end
        player:hud_change(ids["coal_1"], "text", "ap_airship_"..(math.floor(coal_value/10))..".png")
        player:hud_change(ids["coal_2"], "text", "ap_airship_"..(math.floor(coal_value%10))..".png")]]--

        --[[ap_airship.animate_gauge(player, ids, "water_pt_", water_gauge_x, water_gauge_y, water)
        ap_airship.animate_gauge(player, ids, "press_pt_", press_gauge_x, press_gauge_y, pressure)]]--
    else
        ids = {}

        ids["title"] = player:hud_add({
            hud_elem_type = "text",
            position  = {x = 0, y = 1},
            offset    = {x = screen_pos_x + 240, y = screen_pos_y - 100},
            text      = "Airship engine state",
            alignment = 0,
            scale     = { x = 100, y = 30},
            number    = 0xFFFFFF,
        })

        ids["bg"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = screen_pos_x, y = screen_pos_y},
            text      = "ap_airship_hud_panel.png",
            scale     = { x = 0.5, y = 0.5},
            alignment = { x = 1, y = 0 },
        })

        ids["throttle"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = throttle_x, y = throttle_y},
            text      = "ap_airship_throttle.png",
            scale     = { x = 0.5, y = 0.5},
            alignment = { x = 1, y = 0 },
        })

        ids["gs_bg"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 0, y = 1 },
            offset        = { x = gs_ind_x, y = gs_ind_y },
            text          = "ap_airship_ind_gs_bg.png",
            scale         = { x = 1, y = 1 },
            alignment     = { x = 1, y = -1 },
        })

        ids["gs_hor"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 0, y = 1 },
            offset        = { x = gs_ind_x, y = gs_ind_range_ymin },
            text          = "ap_airship_ind_gs_lh.png",
            scale         = { x = 170, y = 1 },
            alignment     = { x = 1, y = -1 },
        })

        ids["gs_vert"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 0, y = 1 },
            offset        = { x = gs_ind_range_xmin, y = gs_ind_y },
            text          = "ap_airship_ind_gs_lv.png",
            scale         = { x = 1, y = 170 },
            alignment     = { x = 1, y = -1 },
        })

        ids["gs_fg"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 0, y = 1 },
            offset        = { x = gs_ind_x, y = gs_ind_y },
            text          = "ap_airship_ind_gs_fg.png",
            scale         = { x = 1, y = 1 },
            alignment     = { x = 1, y = -1 },
        })

        ids["gs_caption"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 0, y = 1 },
            offset        = { x = gs_ind_zero_x, y = gs_ind_y - 170 },
            text          = "Ground Speed",
            scale         = { x = 1, y = 1 },
            alignment     = { x = 0, y = -1 },
            number        = 0xFFFFFF,
        })

        --[[ids["coal_1"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = coal_1_x, y = coal_1_y},
            text      = "ap_airship_0.png",
            scale     = { x = 0.5, y = 0.5},
            alignment = { x = 1, y = 0 },
        })

        ids["coal_2"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = coal_2_x, y = coal_2_y},
            text      = "ap_airship_0.png",
            scale     = { x = 0.5, y = 0.5},
            alignment = { x = 1, y = 0 },
        })]]--
        
        --[[ids["water_pt_1"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })

        ids["water_pt_2"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["water_pt_3"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["water_pt_4"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["water_pt_5"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["water_pt_6"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["water_pt_7"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = water_gauge_x, y = water_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })

        ids["press_pt_1"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["press_pt_2"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["press_pt_3"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["press_pt_4"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["press_pt_5"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["press_pt_6"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["press_pt_7"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = press_gauge_x, y = press_gauge_y},
            text      = "ap_airship_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })]]--

        ap_airship.hud_list[player_name] = ids
    end
end


function ap_airship.remove_hud(player)
    if player then
        local player_name = player:get_player_name()
        --minetest.chat_send_all(player_name)
        local ids = ap_airship.hud_list[player_name]
        if ids then
            --player:hud_remove(ids["altitude"])
            --player:hud_remove(ids["time"])
            for key in pairs(ids) do
                player:hud_remove(ids[key])
            end
        end
        ap_airship.hud_list[player_name] = nil
    end

end
