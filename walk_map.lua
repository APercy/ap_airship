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

function ap_airship.cabin_map(pos, dpos)
    local orig_pos = ap_airship.copy_vector(pos)
    local position = ap_airship.copy_vector(dpos)
    local new_pos = ap_airship.copy_vector(dpos)

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
        new_pos.z = ap_airship.clamp(new_pos.z, 3, 109)
        new_pos.x = ap_airship.clamp(new_pos.x, -43, 43)
    end
    new_pos.y = 0

    --minetest.chat_send_all("x: "..new_pos.x.." - z: "..new_pos.z)
    return new_pos
end

function ap_airship.ladder_map(pos, dpos)
    local orig_pos = steampunk_blimp.copy_vector(pos)
    local position = steampunk_blimp.copy_vector(dpos)
    local new_pos = steampunk_blimp.copy_vector(dpos)
    new_pos.z = steampunk_blimp.clamp(new_pos.z, 112, 118)
    new_pos.x = steampunk_blimp.clamp(new_pos.x, -8.42, -2)

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
                    {object = self._passengers_base_pos[index].object, gain = 0.1,
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
    for i = 5,1,-1 
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
                    local result_pos = get_result_pos(self, player, i)
                    local y_rot = 0
                    if result_pos then
                        y_rot = result_pos.y -- the only field that returns a rotation
                        local new_pos = ap_airship.copy_vector(self._passengers_base_pos[i])
                        new_pos.x = new_pos.x - result_pos.z
                        new_pos.z = new_pos.z - result_pos.x
                        --minetest.chat_send_all(dump(new_pos))
                        --local pos_d = ap_airship.boat_lower_deck_map(self._passengers_base_pos[i], new_pos)
                        local pos_d = ap_airship.navigate_deck(self._passengers_base_pos[i], new_pos, player)
                        --minetest.chat_send_all(dump(height))
                        self._passengers_base_pos[i] = ap_airship.copy_vector(pos_d)
                        self._passengers_base[i]:set_attach(self.object,'',self._passengers_base_pos[i],{x=0,y=0,z=0})
                    end
                    --minetest.chat_send_all(dump(self._passengers_base_pos[i]))
                    player:set_attach(self._passengers_base[i], "", {x = 0, y = 0, z = 0}, {x = 0, y = y_rot, z = 0})
                else
                    --self._passengers[i] = nil
                end
            end
        end
    end
end

