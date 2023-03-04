function ap_airship.testDamage(self, velocity, position)
    if self._last_accell == nil then return end
    local p = position --self.object:get_pos()
    local collision = false
    local low_node_pos = -2.5
    if self._last_vel == nil then return end
    --lets calculate the vertical speed, to avoid the bug on colliding on floor with hard lag
    if math.abs(velocity.y - self._last_vel.y) > 2 then
		local noded = airutils.nodeatpos(airutils.pos_shift(p,{y=low_node_pos}))
	    if (noded and noded.drawtype ~= 'airlike') then
		    collision = true
	    else
            self.object:set_velocity(self._last_vel)
            --self.object:set_acceleration(self._last_accell)
            self.object:set_velocity(vector.add(velocity, vector.multiply(self._last_accell, self.dtime/8)))
        end
    end
    local impact = math.abs(ap_airship.get_hipotenuse_value(velocity, self._last_vel))
    if impact > 2 then
        if self.colinfo then
            collision = self.colinfo.collides
            --minetest.chat_send_all(impact)
        end
    end

    if collision then
        --self.object:set_velocity({x=0,y=0,z=0})
        local damage = impact -- / 2
        minetest.sound_play("ap_airship_collision", {
            --to_player = self.driver_name,
            object = self.object,
            max_hear_distance = 15,
            gain = 1.0,
            fade = 0.0,
            pitch = 1.0,
        }, true)
        if damage > 5 then
            self._power_lever = 0
        end

        if self.driver_name then
            local player_name = self.driver_name

            local player = minetest.get_player_by_name(player_name)
            if player then
		        if player:get_hp() > 0 then
			        player:set_hp(player:get_hp()-(damage/2))
		        end
            end
            if self._passenger ~= nil then
                local passenger = minetest.get_player_by_name(self._passenger)
                if passenger then
		            if passenger:get_hp() > 0 then
			            passenger:set_hp(passenger:get_hp()-(damage/2))
		            end
                end
            end
        end

    end
end

local function do_attach(self, player, slot)
    if slot == 0 then return end
    if self._passengers[slot] == nil then
        local name = player:get_player_name()
        --minetest.chat_send_all(self.driver_name)
        self._passengers[slot] = name
        player:set_attach(self._passengers_base[slot], "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player_api.player_attached[name] = true
    end
end

function ap_airship.check_passenger_is_attached(self, name)
    local is_attached = false
    if is_attached == false then
        for i = 5,1,-1 
        do 
            if self._passengers[i] == name then
                is_attached = true
                break
            end
        end
    end
    return is_attached
end

--this method checks each 1 second for a disconected player who comes back
function ap_airship.rescueConnectionFailedPassengers(self)
    self._disconnection_check_time = self._disconnection_check_time + self.dtime
    if self._disconnection_check_time > 1 then
        --minetest.chat_send_all(dump(self._passengers))
        self._disconnection_check_time = 0
        for i = 5,1,-1 
        do 
            if self._passengers[i] then
                local player = minetest.get_player_by_name(self._passengers[i])
                if player then --we have a player!
                    if player_api.player_attached[self._passengers[i]] == nil then --but isn't attached?
                        --minetest.chat_send_all("okay")
		                if player:get_hp() >= 0 then
                            self._passengers[i] = nil --clear the slot first
                            do_attach(self, player, i) --attach
                        else
                            --ap_airship.dettachPlayer(self, player)
		                end
                    end
                end
            end
        end
    end
end

-- attach passenger
function ap_airship.attach_pax(self, player, slot)
    slot = slot or 0
    local name = player:get_player_name()

    --verify if is locked to non-owners
    if self._passengers_locked == true then
        local can_bypass = minetest.check_player_privs(player, {protection_bypass=true})
        local is_shared = false
        if name == self.owner or can_bypass then is_shared = true end
        for k, v in pairs(self._shared_owners) do
            if v == name then
                is_shared = true
                break
            end
        end
        if is_shared == false then
            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> This airship is currently locked for non-owners"))
            return
        end
    end


    if slot > 0 then
        do_attach(self, player, slot)
        return
    end
    --minetest.chat_send_all(dump(self._passengers))

    --now yes, lets attach the player
    --randomize the seat
    local t = {1,2,3,4,5}
    for i = 1, #t*2 do
        local a = math.random(#t)
        local b = math.random(#t)
        t[a],t[b] = t[b],t[a]
    end

    --minetest.chat_send_all(dump(t))

    local i=0
    for k,v in ipairs(t) do
        i = t[k]
        if self._passengers[i] == nil then
            do_attach(self, player, i)
            if name == self.owner then
                --put the owner on cabin directly
                self._passengers_base_pos[i] = {x=0,y=-29,z=150}
                self._passengers_base[i]:set_attach(self.object,'',self._passengers_base_pos[i],{x=0,y=0,z=0})
            end
            break
        end
    end
end

function ap_airship.dettach_pax(self, player, side)
    side = side or "r"
    if player then
        local name = player:get_player_name() --self._passenger
        ap_airship.remove_hud(player)

        -- passenger clicked the object => driver gets off the vehicle
        for i = 5,1,-1 
        do 
            if self._passengers[i] == name then
                self._passengers[i] = nil
                self._passengers_base_pos[i] = ap_airship.copy_vector(ap_airship.passenger_pos[i])
                --break
            end
        end

        -- detach the player
        player:set_detach()
        player_api.player_attached[name] = nil
        player_api.set_animation(player, "stand")

        -- move player down
        minetest.after(0.1, function(pos)
            local rotation = self.object:get_rotation()
            local direction = rotation.y

            if side == "l" then
                direction = direction - math.rad(180)
            end

            local move = 5
            pos.x = pos.x + move * math.cos(direction)
            pos.z = pos.z + move * math.sin(direction)
            if self.isinliquid then
                pos.y = pos.y + 1
            else
                pos.y = pos.y - 2.5
            end
            player:set_pos(pos)
        end, player:get_pos())
    end
end

function ap_airship.textures_copy()
    local tablecopy = {}
    for k, v in pairs(ap_airship.textures) do
      tablecopy[k] = v
    end
    return tablecopy
end

function ap_airship.table_copy(table_here)
    local tablecopy = {}
    for k, v in pairs(table_here) do
      tablecopy[k] = v
    end
    return tablecopy
end

local function paint(self)
    local l_textures = ap_airship.textures_copy()
    for _, texture in ipairs(l_textures) do
        local indx = texture:find('wool_blue.png')
        if indx then
            l_textures[_] = "wool_".. self.color..".png"
        end
        indx = texture:find('wool_yellow.png')
        if indx then
            l_textures[_] = "wool_".. self.color2..".png"
        end
        indx = texture:find('ap_airship_alpha_logo.png')
        if indx then
            l_textures[_] = self.logo
        end
    end
    self.object:set_properties({textures=l_textures})
end

function ap_airship.set_logo(self, texture_name)
    if texture_name == "" or texture_name == nil then
        self.logo = "ap_airship_alpha_logo.png"
    elseif texture_name then
        self.logo = texture_name
    end
    paint(self)
end

--painting
function ap_airship.paint(self, colstr)
    if colstr then
        self.color = colstr
        paint(self)
    end
end
function ap_airship.paint2(self, colstr)
    if colstr then
        self.color2 = colstr
        paint(self)
    end
end

-- destroy the boat
function ap_airship.destroy(self, overload)
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end

    local pos = self.object:get_pos()
    if self._passengers_base[1] then self._passengers_base[1]:remove() end
    if self._passengers_base[2] then self._passengers_base[2]:remove() end
    if self._passengers_base[3] then self._passengers_base[3]:remove() end
    if self._passengers_base[4] then self._passengers_base[4]:remove() end
    if self._passengers_base[5] then self._passengers_base[5]:remove() end
    if self._cabin_interactor then self._cabin_interactor:remove() end
    if self._control_interactor then self._control_interactor:remove() end

    airutils.destroy_inventory(self)
    self.object:remove()

    pos.y=pos.y+2
    --[[for i=1,7 do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:steel_ingot')
    end

    for i=1,7 do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:mese_crystal')
    end]]--

    --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'ap_airship:boat')
    --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:diamond')

    --[[local total_biofuel = math.floor(self._energy) - 1
    for i=0,total_biofuel do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'biofuel:biofuel')
    end]]--
    if overload then
        local stack = ItemStack(self.item)
        local item_def = stack:get_definition()
        
        if item_def.overload_drop then
            for _,item in pairs(item_def.overload_drop) do
                minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},item)
            end
            return
        end
    end
    local stack = ItemStack(self.item)
    local item_def = stack:get_definition()
    if self.hull_integrity then
        local boat_wear = math.floor(65535*(1-(self.hull_integrity/item_def.hull_integrity)))
        stack:set_wear(boat_wear)
    end
    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5}, stack)
end

--returns 0 for old, 1 for new
function ap_airship.detect_player_api(player)
    local player_proterties = player:get_properties()
    local mesh = "character.b3d"
    if player_proterties.mesh == mesh then
        local models = player_api.registered_models
        local character = models[mesh]
        if character then
            if character.animations.sit.eye_height then
                return 1
            else
                return 0
            end
        end
    end

    return 0
end

function ap_airship.checkAttach(self, player)
    local retVal = false
    if player then
        local player_attach = player:get_attach()
        if player_attach then
            for i = 5,1,-1 
            do 
                if player_attach == self._passengers_base[i] then
                    retVal = true
                    break
                end
            end
        end
    end
    return retVal
end

function ap_airship.engineSoundPlay(self)
    --sound
    if self.sound_handle then minetest.sound_stop(self.sound_handle) end
    if self.sound_handle_engine then minetest.sound_stop(self.sound_handle_engine) end
    if self.object then
        self.sound_handle = minetest.sound_play({name = "default_furnace_active"},
            {object = self.object, gain = 0.2,
                max_hear_distance = 5,
                loop = true,})

        self.sound_handle_engine = minetest.sound_play({name = "ap_airship_engine"},--"default_item_smoke"},
            {object = self.object, gain = 3.0,
                pitch = 0.4+((math.abs(self._power_lever)/100)/2),
                max_hear_distance = 32,
                loop = true,})
    end
end

function ap_airship.engine_set_sound_and_animation(self)
    if self._last_applied_power ~= self._power_lever then
        --minetest.chat_send_all('test2')
        self._last_applied_power = self._power_lever
        self.object:set_animation_frame_speed(ap_airship.iddle_rotation + (self._power_lever*100))
        if self._last_sound_update == nil then self._last_sound_update = self._power_lever end
        if math.abs(self._last_sound_update - self._power_lever) > 5 then
            self._last_sound_update = self._power_lever
            ap_airship.engineSoundPlay(self)
        end
    end
    if self._engine_running == false then
        self._power_lever = 0
        self.object:set_animation_frame_speed(0)
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
            --self.object:set_animation_frame_speed(0)
        end
        if self.sound_handle_engine then
            minetest.sound_stop(self.sound_handle_engine)
            self.sound_handle_engine = nil
        end
    end
end


function ap_airship.start_furnace(self)
    if self._engine_running then
	    self._engine_running = false
        -- sound and animation
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end
    elseif self._engine_running == false and self._energy > 0 then
	    self._engine_running = true
        -- sound
        if self.sound_handle then minetest.sound_stop(self.sound_handle) end
        if self.object then
            self.sound_handle = minetest.sound_play({name = "default_furnace_active"},
                {object = self.object, gain = 0.2,
                    max_hear_distance = 5,
                    loop = true,})
        end
    end
end

function ap_airship.copy_vector(original_vector)
    local tablecopy = {}
    for k, v in pairs(original_vector) do
      tablecopy[k] = v
    end
    return tablecopy
end

