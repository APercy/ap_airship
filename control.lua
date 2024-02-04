--global constants

ap_airship.vector_up = vector.new(0, 1, 0)

function ap_airship.check_node_below(obj)
	local pos_below = obj:get_pos()
	pos_below.y = pos_below.y - 0.1
	local node_below = minetest.get_node(pos_below).name
	local nodedef = minetest.registered_nodes[node_below]
	local touching_ground = not nodedef or -- unknown nodes are solid
			nodedef.walkable or false
	local liquid_below = not touching_ground and nodedef.liquidtype ~= "none"
	return touching_ground, liquid_below
end

function ap_airship.powerAdjust(self,dtime,factor,dir,max_power)
    local max = max_power or 100
    local add_factor = factor/2
    add_factor = add_factor * (dtime/ap_airship.ideal_step) --adjusting the command speed by dtime
    local power_index = self._power_lever

    if dir == 1 then
        if self._power_lever < max then
            self._power_lever = self._power_lever + add_factor
        end
        if self._power_lever > max then
            self._power_lever = max
        end
    end
    if dir == -1 then
        self._power_lever = self._power_lever - add_factor
        if self._power_lever < -15 then self._power_lever = -15 end
    end
end

function ap_airship.set_lift(self, longit_speed, direction)
    direction = direction or 0
    local vel = self.object:get_velocity()

    self._is_going_up = false
    local work_speed = math.abs(longit_speed)
    if ap_airship.max_speed < work_speed then work_speed = ap_airship.max_speed end --limit the range
    local normal_lift = 0.15
    local extra_lift = 0.15
    local abs_baloon_buoyancy = normal_lift + ((work_speed*extra_lift)/ap_airship.max_speed)
    local max_v_speed = 0.5
    if direction == 1 and vel.y <= max_v_speed then
        --if self._boiler_pressure > 0 then
            self._baloon_buoyancy = abs_baloon_buoyancy
        --end
        self._is_going_up = true
    elseif direction == -1 and vel.y >= -1*max_v_speed then
        self._baloon_buoyancy = -1*abs_baloon_buoyancy
    end
end

-- control can be -100 to +100
function ap_airship.set_rudder_by_percent(self, control)
    local rudder_limit = 30
    local sign = 1
    if control < 0 then sign = -1 end
    if math.abs(control) > 100 then control = 100*sign end
    self._rudder_angle = ((math.abs(control)*rudder_limit)/100)*sign
end

function ap_airship.get_rudder_by_percent(self)
    local rudder_limit = 30
    local sign = 1
    if self._rudder_angle < 0 then sign = -1 end
    if math.abs(self._rudder_angle) > 30 then self._rudder_angle = 30*sign end
    return ((math.abs(self._rudder_angle)*100)/rudder_limit)*sign
end 


function ap_airship.control(self, dtime, hull_direction, longit_speed, accel)
    if self._last_time_command == nil then self._last_time_command = 0 end
    self._last_time_command = self._last_time_command + dtime
    if self._last_time_command > 1 then self._last_time_command = 1 end
	local player = nil
    if self.driver_name then
        player = minetest.get_player_by_name(self.driver_name)
    end
    local retval_accel = accel;
    
	-- player control
    local ctrl = nil
	if player and self._at_control == true then
		ctrl = player:get_player_control()
		local max_speed_anchor = 0.2

        if self.anchored == false then
            local factor = 1
            if ctrl.up then
                local can_acc = true
                if self._power_lever >= 82 then can_acc = false end
                if ctrl.aux1 then can_acc = true end
                if can_acc then
                    ap_airship.powerAdjust(self, dtime, factor, 1)
                end
            elseif ctrl.down then
                ap_airship.powerAdjust(self, dtime, factor, -1)
            else
                --self.object:set_animation_frame_speed(ap_airship.iddle_rotation)
            end
        else
            --anchor away, so stop!
            self._power_lever = 0
        end
        if not ctrl.aux1 and self._power_lever < 0 then self._power_lever = 0 end

        --control lift
		if ctrl.jump then
            ap_airship.set_lift(self, longit_speed, 1)
            --if self._boiler_pressure > 0 then
            --end
            self._is_going_up = true
		elseif ctrl.sneak then
            ap_airship.set_lift(self, longit_speed, -1)
		end
        --end lift

        --check if is near the ground, so revert the flight mode
        local noded = airutils.nodeatpos(airutils.pos_shift(self.object:get_pos(),{y=-4}))
        if (noded and noded.drawtype ~= 'airlike') then
            --avoid liquids
            if noded.drawtype == 'liquid' then
                --self._baloon_buoyancy = abs_baloon_buoyancy*2
            end
        end


		-- rudder
        local rudder_limit = 30
        local speed = 30
        local curr_control = ap_airship.get_rudder_by_percent(self)
		if ctrl.right then
            ap_airship.set_rudder_by_percent(self, curr_control-speed*dtime)
		elseif ctrl.left then
            ap_airship.set_rudder_by_percent(self, curr_control+speed*dtime)
		end
	end

    --corrections from automation
    if self._power_lever > 100 then self._power_lever = 100 end
    if self._power_lever < -100 then self._power_lever = -100 end

    --engine acceleration calc
    local engineacc = (self._power_lever * ap_airship.max_engine_acc) / 100;

    --do not exceed
    if longit_speed > ap_airship.max_speed then
        engineacc = engineacc - (longit_speed-ap_airship.max_speed)
    end

    if engineacc ~= nil then
        retval_accel=vector.add(accel,vector.multiply(hull_direction,engineacc))
    end
    --minetest.chat_send_all('paddle: '.. paddleacc)


    if longit_speed > 0 then
        if ctrl then
            if ctrl.right or ctrl.left then
            else
                ap_airship.rudder_auto_correction(self, longit_speed, dtime)
            end
        else
            ap_airship.rudder_auto_correction(self, longit_speed, dtime)
        end
    end

    ap_airship.buoyancy_auto_correction(self, self.dtime)

    return retval_accel
end

function ap_airship.rudder_auto_correction(self, longit_speed, dtime)
    local factor = 1
    if self._rudder_angle > 0 then factor = -1 end
    local correction = (ap_airship.rudder_limit*(longit_speed/2000)) * factor * (dtime/ap_airship.ideal_step)
    local before_correction = self._rudder_angle
    local new_rudder_angle = self._rudder_angle + correction
    if math.sign(before_correction) ~= math.sign(new_rudder_angle) then
        self._rudder_angle = 0
    else
        self._rudder_angle = new_rudder_angle
    end
end

function ap_airship.buoyancy_auto_correction(self, dtime)
    local factor = 1
    --minetest.chat_send_player(self.driver_name, "antes: " .. self._baloon_buoyancy)
    if self._baloon_buoyancy > 0 then factor = -1 end
    local time_correction = (dtime/ap_airship.ideal_step)
    if time_correction < 1 then time_correction = 1 end
    local intensity = 0.001
    local correction = (intensity*factor) * time_correction
    if math.abs(correction) > 0.005 then correction = 0.005 * math.sign(correction) end
    --minetest.chat_send_player(self.driver_name, correction)
    local before_correction = self._baloon_buoyancy
    local new_baloon_buoyancy = self._baloon_buoyancy + correction
    if math.sign(before_correction) ~= math.sign(new_baloon_buoyancy) then
        self._baloon_buoyancy = 0
    else
        self._baloon_buoyancy = new_baloon_buoyancy
    end
    --minetest.chat_send_player(self.driver_name, "depois: " .. self._baloon_buoyancy)
end

