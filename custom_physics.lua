local min = math.min
local abs = math.abs

function ap_airship.physics(self)
    local friction = 0.996
	local vel=self.object:get_velocity()
		-- dumb friction
	if self.isonground and not self.isinliquid then
        --minetest.chat_send_all("with friction")
		vel = {x=vel.x*friction,
								y=vel.y,
								z=vel.z*friction}
        self.object:set_velocity(vel)
	end
	
	-- bounciness
	if self.springiness and self.springiness > 0 then
		local vnew = vector.new(vel)
		
		if not self.collided then						-- ugly workaround for inconsistent collisions
			for _,k in ipairs({'y','z','x'}) do
				if vel[k]==0 and abs(self.lastvelocity[k])> 0.1 then
					vnew[k]=-self.lastvelocity[k]*self.springiness
				end
			end
		end
		
		if not vector.equals(vel,vnew) then
			self.collided = true
		else
			if self.collided then
				vnew = vector.new(self.lastvelocity)
			end
			self.collided = false
		end
		--minetest.chat_send_all("vnew")
		self.object:set_velocity(vnew)
    end
    --[[else
        self.object:set_pos(self.object:get_pos())
        if not self.isonground then
            --minetest.chat_send_all("test")
            self.object:set_velocity(vel)
        end
	end]]--

	--buoyancy
	local surface = nil
	local surfnodename = nil
	local spos = airutils.get_stand_pos(self)
	spos.y = spos.y+0.01
	-- get surface height
	local snodepos = airutils.get_node_pos(spos)
	local surfnode = airutils.nodeatpos(spos)
	while surfnode and (surfnode.drawtype == 'liquid' or surfnode.drawtype == 'flowingliquid') do
		surfnodename = surfnode.name
		surface = snodepos.y +0.5
		if surface > spos.y+self.height then break end
		snodepos.y = snodepos.y+1
		surfnode = airutils.nodeatpos(snodepos)
	end

    local new_velocity = nil

    local accell = {x=0, y=0, z=0}
    self.water_drag = 0.1
    self.object:move_to(self.object:get_pos())
    local time_correction = (self.dtime/ap_airship.ideal_step)
    if time_correction < 1 then time_correction = 1 end
    local y_accel = self._baloon_buoyancy*time_correction
    --minetest.chat_send_all(y_accel)
    local max_y_acell = 0.3
    if y_accel > max_y_acell then y_accel = max_y_acell end
    if y_accel < (-1*max_y_acell) then y_accel = -1*max_y_acell end


    self.isinliquid = false
    if self._baloon_buoyancy == 0 then
        local velocity = vector.new(vel)
        velocity.y = velocity.y - (velocity.y/100)
        self.object:set_velocity(velocity)
    end
    --minetest.chat_send_all("_baloon_buoyancy: "..self._baloon_buoyancy.." - dtime: "..self.dtime.." - ideal: "..ap_airship.ideal_step)

    local max_y_speed = 1.5
    local curr_y_speed = vel.y
    if curr_y_speed < max_y_speed then
        airutils.set_acceleration(self.object,{x=0,y=y_accel,z=0})
    else
        airutils.set_acceleration(self.object,{x=0,y=0,z=0})
    end
    
end
