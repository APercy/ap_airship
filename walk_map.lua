function ap_airship.clamp(value, min, max)
    local retVal = value
    if value < min then retVal = min end
    if value > max then retVal = max end
    --minetest.chat_send_all(value .. " - " ..retVal)
    return retVal
end

function ap_airship.reclamp(value, min, max)
    local retVal = value
    local mid = (max-min)/2
    if value > min and value <= (min+mid) then retVal = min end
    if value < max and value > (max-mid) then retVal = max end
    --minetest.chat_send_all(value .. " - return: " ..retVal .. " - mid: " .. mid)
    return retVal
end

local function is_obstacle_zone(pos, start_point, end_point)
    local retVal = ap_airship.table_copy(pos)

    local min_x = 0
    local min_z = 0
    local max_x = 0
    local max_z = 0

    if start_point.x <= end_point.x then min_x = start_point.x else min_x = end_point.x end
    if start_point.z <= end_point.z then min_z = start_point.z else min_z = end_point.z end
    if start_point.x > end_point.x then max_x = start_point.x else max_x = end_point.x end
    if start_point.z > end_point.z then max_z = start_point.z else max_z = end_point.z end

    local mid_x = (max_x - min_x)/2
    local mid_z = (max_z - min_z)/2

    if pos.x < max_x and pos.x > min_x+mid_x and
            pos.z < max_z and pos.z > min_z then
        retVal.x = max_x + 1
        return retVal
    end
    if pos.x > min_x and pos.x <= min_x+mid_x and
            pos.z < max_z and pos.z > min_z then
        retVal.x = min_x - 1
        return retVal
    end

    local death_zone = 1.5 --to avoid the "slip" when colliding in y direction
    if pos.z < max_z + death_zone and pos.z > min_z+mid_z and
            pos.x > min_x and pos.x < max_x then
        retVal.z = max_z + 1
        return retVal
    end
    if pos.z > min_z - death_zone and pos.z <= min_z+mid_z and
            pos.x > min_x and pos.x < max_x then
        retVal.z = min_z - 1
        return retVal
    end

    return retVal
end

function ap_airship.cabin_map(pos, dpos)
    local orig_pos = ap_airship.copy_vector(pos)
    local position = ap_airship.copy_vector(dpos)
    local new_pos = ap_airship.copy_vector(dpos)

    new_pos = is_obstacle_zone(new_pos, {x=12, z=153}, {x=2.5, z=143})
    new_pos = is_obstacle_zone(new_pos, {x=-12, z=153}, {x=-2.5, z=143})
    new_pos = is_obstacle_zone(new_pos, {x=12, z=140}, {x=2.5, z=130})
    new_pos = is_obstacle_zone(new_pos, {x=-12, z=140}, {x=-2.5, z=130})
    new_pos = is_obstacle_zone(new_pos, {x=12, z=127}, {x=2.5, z=117})

    --limit to the cabin
    new_pos.z = ap_airship.clamp(new_pos.z, 112, 164)
    new_pos.y = -29
    new_pos.x = ap_airship.clamp(new_pos.x, -8.42, 8.42)

    --minetest.chat_send_all("x: "..new_pos.x.." - z: "..new_pos.z)
    return new_pos
end

local function is_cabin_zone(pos)
    local cabin_zone = false
    if pos.z > -20 and pos.z <= 200 and pos.x > -8 and pos.x < 8 then cabin_zone = true end
    return cabin_zone
end

local function is_ladder_zone(pos)
    local ladder_zone = false
    if pos.z <= 120 and pos.z >= 109 and pos.x > -9 and pos.x < -2 then ladder_zone = true end
    return ladder_zone
end

function ap_airship.passengers_deck_map(pos, dpos)
    local orig_pos = ap_airship.copy_vector(pos)
    local position = ap_airship.copy_vector(dpos)
    local new_pos = ap_airship.copy_vector(dpos)
    local ladder_zone = is_ladder_zone(pos)

    if ladder_zone then
        --limiting ladder space
        new_pos.z = ap_airship.clamp(new_pos.z, 3, 118)
        new_pos.x = ap_airship.clamp(new_pos.x, -8.42, -2)
    else
        --limiting upper deck
        if math.abs(pos.x) < 4 and pos.z <= 3 then --corridor to exit
            new_pos.z = ap_airship.clamp(new_pos.z, -115, 5)
            new_pos.x = ap_airship.clamp(new_pos.x, -3, 3)
        else
            new_pos.z = ap_airship.clamp(new_pos.z, 3, 109)
            new_pos.x = ap_airship.clamp(new_pos.x, -43, 43)
        end

        new_pos = is_obstacle_zone(new_pos, {x=30, z=10}, {x=2, z=48})
        new_pos = is_obstacle_zone(new_pos, {x=-30, z=10}, {x=-2, z=48})

        new_pos = is_obstacle_zone(new_pos, {x=30, z=55}, {x=2, z=90})
        new_pos = is_obstacle_zone(new_pos, {x=-30, z=55}, {x=-2, z=90})
    end
    new_pos.y = 0

    --minetest.chat_send_all("x: "..new_pos.x.." - z: "..new_pos.z)
    return new_pos
end

function ap_airship.ladder_map(pos, dpos)
    local orig_pos = ap_airship.copy_vector(pos)
    local position = ap_airship.copy_vector(dpos)
    local new_pos = ap_airship.copy_vector(dpos)
    new_pos.z = ap_airship.clamp(new_pos.z, 112, 117)
    new_pos.x = ap_airship.clamp(new_pos.x, -8.42, -2)

    return new_pos
end

function ap_airship.navigate_deck(pos, dpos, player)
    local pos_d = dpos
    local ladder_zone = is_ladder_zone(pos)
    
    local upper_deck_y = 0
    local lower_deck_y = -29
    local cabin_zone = is_cabin_zone(pos)
    if player then
        if pos.y == upper_deck_y then
            pos_d = ap_airship.passengers_deck_map(pos, dpos)
        elseif pos.y <= lower_deck_y + 5 then
            if ladder_zone == false then
                pos_d = ap_airship.cabin_map(pos, dpos)
            end
        elseif pos.y > lower_deck_y and pos.y < 10 then
            pos_d = ap_airship.ladder_map(pos, dpos)
        end

        local ctrl = player:get_player_control()
        if ctrl.jump or ctrl.sneak then --ladder
            if ladder_zone then
                --minetest.chat_send_all(dump(pos))
                if ctrl.jump then
                    pos_d.y = pos_d.y + 0.9
                    if pos_d.y > upper_deck_y then pos_d.y = upper_deck_y end
                end
                if ctrl.sneak then
                    pos_d.y = pos_d.y - 0.9
                    if pos_d.y < lower_deck_y then pos_d.y = lower_deck_y end
                end
            end
        end
    end
    --minetest.chat_send_all(dump(pos_d))

    return pos_d
end

--note: index variable just for the walk
--this function was improved by Auri Collings on steampunk_blimp
local function get_result_pos(self, player, index)
    local pos = nil
    if player then
        local ctrl = player:get_player_control()

        local direction = player:get_look_horizontal()
        local rotation = self.object:get_rotation()
        direction = direction - rotation.y

        pos = vector.new()

        local y_rot = -math.deg(direction)
        pos.y = y_rot --okay, this is strange to keep here, but as I dont use it anyway...


        if ctrl.up or ctrl.down or ctrl.left or ctrl.right then
            player_api.set_animation(player, "walk", 30)

            local speed = 0.4

            dir = vector.new(ctrl.up and -1 or ctrl.down and 1 or 0, 0, ctrl.left and 1 or ctrl.right and -1 or 0)
            dir = vector.normalize(dir)
            dir = vector.rotate(dir, {x = 0, y = -direction, z = 0})

            local time_correction = (self.dtime/ap_airship.ideal_step)
            local move = speed * time_correction

            pos.x = move * dir.x
            pos.z = move * dir.z

            --lets fake walk sound
            if self._passengers_base_pos[index].dist_moved == nil then self._passengers_base_pos[index].dist_moved = 0 end
            self._passengers_base_pos[index].dist_moved = self._passengers_base_pos[index].dist_moved + move;
            if math.abs(self._passengers_base_pos[index].dist_moved) > 5 then
                self._passengers_base_pos[index].dist_moved = 0
                minetest.sound_play({name = "default_wood_footstep"},
                    {object = player, gain = 0.1,
                        max_hear_distance = 5,
                        ephemeral = true,})
            end
        else
            player_api.set_animation(player, "stand")
        end
    end
    return pos
end


function ap_airship.move_persons(self)
    --self._passenger = nil
    if self.object == nil then return end
    for i = ap_airship.max_pos,1,-1 
    do
        local player = nil
        if self._passengers[i] then player = minetest.get_player_by_name(self._passengers[i]) end

        if self.driver_name and self._passengers[i] == self.driver_name then
            --clean driver if it's nil
            if player == nil then
                self._passengers[i] = nil
                self.driver_name = nil
            end
        else
            if self._passengers[i] ~= nil then
                --minetest.chat_send_all("pass: "..dump(self._passengers[i]))
                --the rest of the passengers
                if player then
                    if self._passenger_is_sit[i] == 0 then
                        local result_pos = get_result_pos(self, player, i)
                        local y_rot = 0
                        if result_pos then
                            y_rot = result_pos.y -- the only field that returns a rotation
                            local new_pos = ap_airship.copy_vector(self._passengers_base_pos[i])
                            new_pos.x = new_pos.x - result_pos.z
                            new_pos.z = new_pos.z - result_pos.x
                            --minetest.chat_send_all(dump(new_pos))
                            local pos_d = ap_airship.navigate_deck(self._passengers_base_pos[i], new_pos, player)
                            --minetest.chat_send_all(dump(height))
                            self._passengers_base_pos[i] = ap_airship.copy_vector(pos_d)
                            self._passengers_base[i]:set_attach(self.object,'',self._passengers_base_pos[i],{x=0,y=0,z=0})
                        end
                        --minetest.chat_send_all(dump(self._passengers_base_pos[i]))
                        player:set_attach(self._passengers_base[i], "", {x = 0, y = 0, z = 0}, {x = 0, y = y_rot, z = 0})
                    else
                        local y_rot = 0
                        if self._passenger_is_sit[i] == 1 then y_rot = 0 end
                        if self._passenger_is_sit[i] == 2 then y_rot = 90 end
                        if self._passenger_is_sit[i] == 3 then y_rot = 180 end
                        if self._passenger_is_sit[i] == 4 then y_rot = 270 end
                        player:set_attach(self._passengers_base[i], "", {x = 0, y = 3.6, z = 0}, {x = 0, y = y_rot, z = 0})
                        airutils.sit(player)
                    end
                else
                    --self._passengers[i] = nil
                end
            end
        end
    end
end


