--
-- constants
--
local LONGIT_DRAG_FACTOR = 0.13*0.13
local LATER_DRAG_FACTOR = 2.0

local function right_click_function(self, clicker)
    local message = ""
	if not clicker or not clicker:is_player() then
		return
	end

    local name = clicker:get_player_name()

    local touching_ground, liquid_below = airutils.check_node_below(self.object, 2.5)
    local is_on_ground = self.isinliquid or touching_ground or liquid_below
    local is_under_water = airutils.check_is_under_water(self.object)

    --minetest.chat_send_all('passengers: '.. dump(self._passengers))
    --=========================
    --  form to pilot
    --=========================
    local is_attached = false
    local seat = clicker:get_attach()
    if seat then
        local plane = seat:get_attach()
        if plane == self.object then is_attached = true end
    end

    --check error after being shot for any other mod
    if is_attached == false then
        for i = ap_airship.max_pos,1,-1 
        do 
            if self._passengers[i] == name then
                self._passengers[i] = nil --clear the wrong information
                break
            end
        end
    end

    --shows pilot formspec
    if name ~= self.driver_name then
        local pass_is_attached = ap_airship.check_passenger_is_attached(self, name)

        if pass_is_attached then
            local can_bypass = minetest.check_player_privs(clicker, {protection_bypass=true})
            if clicker:get_player_control().aux1 == true then --lets see the inventory
                local is_shared = false
                if name == self.owner or can_bypass then is_shared = true end
                for k, v in pairs(self._shared_owners) do
                    if v == name then
                        is_shared = trueright_click_function
                        break
                    end
                end
                if is_shared then
                    airutils.show_vehicle_trunk_formspec(self, clicker, ap_airship.trunk_slots)
                end
            else
                ap_airship.pax_formspec(name)
            end
        else
            --first lets clean the boat slots
            --note that when it happens, the "rescue" function will lost the historic
            for i = ap_airship.max_pos,1,-1 
            do 
                if self._passengers[i] ~= nil then
                    local old_player = minetest.get_player_by_name(self._passengers[i])
                    if not old_player then self._passengers[i] = nil end
                end
            end
            --attach normal passenger
            --if self._door_closed == false then
                ap_airship.attach_pax(self, clicker)
            --end
        end
    end

end

local function right_click_controls(self, clicker)
    local message = ""
	if not clicker or not clicker:is_player() then
		return
	end

    local name = clicker:get_player_name()
    local ship_self = nil

    local is_attached = false
    local seat = clicker:get_attach()
    if seat then
        ship_attach = seat:get_attach()
        if ship_attach then
            ship_self = ship_attach:get_luaentity()
            is_attached = true
        end
    end


    if is_attached then
        --minetest.chat_send_all('passengers: '.. dump(ship_self._passengers))
        --=========================
        --  form to pilot
        --=========================
        if ship_self.owner == "" then
            ship_self.owner = name
        end
        local can_bypass = minetest.check_player_privs(clicker, {protection_bypass=true})
        if ship_self.driver_name ~= nil and ship_self.driver_name ~= "" then
            --shows pilot formspec
            if name == ship_self.driver_name then
                ap_airship.pilot_formspec(name)
                return
            end
            --lets take the control by force
            if name == ship_self.owner or can_bypass then
                --require the pilot position now
                ap_airship.owner_formspec(name)
                return
            end
        else
            --check if is on owner list
            local is_shared = false
            if name == ship_self.owner or can_bypass then is_shared = true end
            for k, v in pairs(ship_self._shared_owners) do
                if v == name then
                    is_shared = true
                    break
                end
            end
            --normal user
            if is_shared == false then
                ap_airship.pax_formspec(name)
            else
                --owners
                ap_airship.pilot_formspec(name)
            end
        end
    end
end

local function right_click_cabin(self, clicker)
    local message = ""
	if not clicker or not clicker:is_player() then
		return
	end

    local name = clicker:get_player_name()
    local ship_self = nil

    local is_attached = false
    local seat = clicker:get_attach()
    if seat then
        ship_attach = seat:get_attach()
        if ship_attach then
            ship_self = ship_attach:get_luaentity()
            is_attached = true
        end
    end


    if is_attached then
        --shows pax formspec
        if name == ship_self.driver_name then
            return
        else
            ap_airship.pax_formspec(name)
        end
    end
end

local function right_click_exit(self, clicker)
    local message = ""
	if not clicker or not clicker:is_player() then
		return
	end

    local name = clicker:get_player_name()
    local ship_self = nil

    local is_attached = false
    local seat = clicker:get_attach()
    if seat then
        ship_attach = seat:get_attach()
        if ship_attach then
            ship_self = ship_attach:get_luaentity()
            is_attached = true
        end
    end

    if is_attached then
        local ent, obj = airutils.get_attached_entity(ship_self)
        if ent and obj then
            local name = clicker:get_player_name()
            if ent._inv_id and ent._seats then --to check if is one of my puppies
                local can_enter = false
                --check first if it is the owner
                if not ent.driver_name then
                    if ent._needed_licence then
                        local can_fly = minetest.check_player_privs(clicker, ent._needed_licence)
                        if not can_fly then
                            minetest.chat_send_player(name, core.colorize('#ff0000', S(' >>> You need the priv') .. '"'..ent._needed_licence..'" ' .. S('to fly this plane.')))
                            return
                        end
                    end
                    if ent.owner == name or minetest.check_player_privs(clicker, {protection_bypass=true}) then can_enter = true end
                else
                    local max_seats = table.getn(ent._seats)
                    local count = 1
                    for i = 2,max_seats do
                        if ent._passengers[i] then
                            count = count + 1
                        end
                    end
                    --minetest.chat_send_all("count: "..count.." - seats: "..max_seats)
                    if count < max_seats then can_enter = true end
                end
                if can_enter then
                    ap_airship.dettach_pax(ship_self, clicker, "c")
                    airutils.on_rightclick(ent, clicker)
                end
            end
        else
            ap_airship.pax_formspec(name)
        end
    end
end

local function find_chair_index(self, curr_seat)
    for i = ap_airship.max_seats,1,-1 
    do
        if self._chairs[i] == curr_seat then
            return i
        end
    end
    return 0
end

local function right_click_chair(self, clicker)
    local message = ""
	if not clicker or not clicker:is_player() then
		return
	end

    local name = clicker:get_player_name()
    local ship_self = nil

    local is_attached = false
    local seat = clicker:get_attach()
    if seat then
        ship_attach = seat:get_attach()
        if ship_attach then
            ship_self = ship_attach:get_luaentity()
            is_attached = true
        end
    end

    if is_attached then
        local index = ap_airship.get_passenger_seat_index(ship_self, name)
        if index > 0 then
            local chair_index = find_chair_index(ship_self, self.object)
            --minetest.chat_send_all("index: "..chair_index)
            if ship_self._passenger_is_sit[index] == 0 and chair_index then
                local dest_pos = ship_self._chairs_pos[chair_index]
                if dest_pos then
                    dest_pos.y = dest_pos.y
                    ship_self._passengers_base_pos[index] = dest_pos
                    ship_self._passengers_base[index]:set_attach(ship_self.object,'',ship_self._passengers_base_pos[index],{x=0,y=0,z=0})
                    if math.floor(dest_pos.z) ~= 84 and math.floor(dest_pos.z) ~= 39 then
                        ship_self._passenger_is_sit[index] = 1
                    else
                        ship_self._passenger_is_sit[index] = 3
                    end
                end
            else
                ship_self._passenger_is_sit[index] = 0
                player_api.set_animation(clicker, "walk", 30)
            end
        end
    end
end


--
-- entity
--

minetest.register_entity('ap_airship:control_interactor',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=true,
        collisionbox = {-0.5, 0, -0.5, 0.5, 0.5, 0.5},
	    visual = "mesh",
	    mesh = "ap_airship_stand_base.b3d",
        textures = {"ap_airship_alpha.png",},
	},
    dist_moved = 0,
    max_hp = 65535,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        --minetest.chat_send_all("punch")
        if not puncher or not puncher:is_player() then
            return
        end
    end,

    on_rightclick = right_click_controls,

})

minetest.register_entity('ap_airship:cabin_interactor',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=true,
        collisionbox = {-0.5, 0, -0.5, 0.5, 5, 0.5},
	    visual = "mesh",
	    mesh = "ap_airship_stand_base.b3d",
        textures = {"ap_airship_alpha.png",},
	},
    dist_moved = 0,
    max_hp = 65535,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        --minetest.chat_send_all("punch")
        if not puncher or not puncher:is_player() then
            return
        end
    end,

    on_rightclick = right_click_cabin,

})

minetest.register_entity('ap_airship:exit_interactor',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=true,
        collisionbox = {-0.5, 0, -0.5, 0.5, 3, 0.5},
	    visual = "mesh",
	    mesh = "ap_airship_stand_base.b3d",
        textures = {"ap_airship_alpha.png",},
	},
    dist_moved = 0,
    max_hp = 65535,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        --minetest.chat_send_all("punch")
        if not puncher or not puncher:is_player() then
            return
        end
    end,

    on_rightclick = right_click_exit,

})

-- and item just to run the sit function
minetest.register_entity('ap_airship:chair_interactor',{
    initial_properties = {
	    physical = false,
	    collide_with_objects=true,
        collisionbox = {-0.3, 0, -0.3, 0.3, 1, 0.3},
	    pointable=true,
	    visual = "mesh",
	    mesh = "ap_airship_stand_base.b3d",
        textures = {"ap_airship_alpha.png",},
	},
    dist_moved = 0,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,

    on_rightclick = right_click_chair,
})

minetest.register_entity('ap_airship:ent_collider',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=true,
        collisionbox = {-2, 0, -2, 2, 3, 2},
	    visual = "mesh",
	    mesh = "ap_airship_stand_base.b3d",
        textures = {"ap_airship_alpha.png",},
        pointable=false,
	},
    dist_moved = 0,
    max_hp = 65535,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        --minetest.chat_send_all("punch")
        if not puncher or not puncher:is_player() then
            return
        end
    end,

    on_step = function(self,dtime,colinfo)
	    self.dtime = math.min(dtime,0.2)
	    self.colinfo = colinfo
	    
	    if colinfo then 
		    self.isonground = colinfo.touching_ground
            --inetest.chat_send_all("touching ground: "..self.isonground)
	    end
    end,
})

--
-- seat pivot
--
minetest.register_entity('ap_airship:stand_base',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=false,
        collisionbox = {-2, -2, -2, 2, 0, 2},
	    pointable=false,
	    visual = "mesh",
	    mesh = "ap_airship_stand_base.b3d",
        textures = {"ap_airship_alpha.png",},
	},
    dist_moved = 0,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
})

minetest.register_entity("ap_airship:airship", {
    initial_properties = {
        physical = true,
        collide_with_objects = true, --true,
        collisionbox = {-10, -4.1, -10, 10, 15, 10}, --{-1,0,-1, 1,0.3,1},
        selectionbox = {-2, -4.1, -2, 2,  0, 2},
        visual = "mesh",
        backface_culling = false,
        mesh = "ap_airship_mesh.b3d",
        textures = ap_airship.textures_copy(),
    },
    textures = {},
    driver_name = nil,
    sound_handle = nil,
    static_save = true,
    infotext = "A nice airship",
    lastvelocity = vector.new(),
    hp = 50,
    color = "blue",
    color2 = "white",
    logo = "ap_airship_alpha_logo.png",
    timeout = 0;
    buoyancy = 0.15,
    max_hp = 50,
    anchored = true,
    physics = ap_airship.physics,
    hull_integrity = nil,
    owner = "",
    _vehicle_custom_data = {},
    _shared_owners = {},
    _engine_running = false,
    _power_lever = 0,
    _last_applied_power = 0,
    _at_control = false,
    _rudder_angle = 0,
    _baloon_buoyancy = 0,
    _show_hud = true,
    _energy = 1.0,--0.001,
    _boiler_pressure = 1.0, --min 155 max 310
    _is_going_up = false, --to tell the boiler to lose pressure
    _chairs={}, --chairs obj ids
    _chairs_pos={},
    _passengers = {}, --passengers list
    _passengers_base = {}, --obj ids
    _passenger_is_sit = {}, -- 0, 1, 2, 3 or 4 ==> stand, 0, 90, 180, 270 --the sit rotation
    _passengers_base_pos = ap_airship.copy_vector({}),
    _passengers_locked = false,
    _disconnection_check_time = 0,
    _inv = nil,
    _inv_id = "",
    _rescue_plane = false,
    _name_color = 0,
    _name_hor_aligment = 3.0,
    _simple_attach_pos = {x=0,y=-35,z=-70},
    _simple_attach_ent_list = {"albatros_d5:albatros_d5","sopwith_f1_camel:sopwith_f1_camel","supercub:supercub"},

    item = "ap_airship:airship",

    get_staticdata = function(self) -- unloaded/unloads ... is now saved
        return minetest.serialize({
            stored_baloon_buoyancy = self._baloon_buoyancy,
            stored_energy = self._energy,
            stored_owner = self.owner,
            stored_shared_owners = self._shared_owners,
            stored_hp = self.hp,
            stored_color = self.color,
            stored_color2 = self.color2,
            stored_logo = self.logo,
            stored_anchor = self.anchored,
            stored_hull_integrity = self.hull_integrity,
            stored_item = self.item,
            stored_inv_id = self._inv_id,
            stored_passengers = self._passengers, --passengers list
            stored_passengers_locked = self._passengers_locked,
            stored_vehicle_custom_data = self._vehicle_custom_data or {},
            stored_ship_name = self._ship_name,
            stored_rescue_plane = self._rescue_plane,
            remove = self._remove or false,
        })
    end,

	on_deactivate = function(self)
        airutils.save_inventory(self)
        if self.sound_handle then minetest.sound_stop(self.sound_handle) end
        if self.sound_handle_engine then minetest.sound_stop(self.sound_handle_engine) end
	end,

    on_activate = function(self, staticdata, dtime_s)
        --minetest.chat_send_all('passengers: '.. dump(self._passengers))
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.deserialize(staticdata) or {}

            self._baloon_buoyancy = data.stored_baloon_buoyancy or 0
            self._energy = data.stored_energy or 0
            self.owner = data.stored_owner or ""
            self._shared_owners = data.stored_shared_owners or {}
            self.hp = data.stored_hp or 50
            self.color = data.stored_color or "blue"
            self.color2 = data.stored_color2 or "white"
            self.logo = data.stored_logo or "ap_airship_alpha_logo.png"
            self.anchored = data.stored_anchor or false
            self.buoyancy = data.stored_buoyancy or 0.15
            self.hull_integrity = data.stored_hull_integrity
            self.item = data.stored_item
            self._inv_id = data.stored_inv_id
            self._passengers = data.stored_passengers or ap_airship.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil, [6]=nil, [7]=nil, [8]=nil, [9]=nil, [10]=nil, [11]=nil, [12]=nil})
            self._passengers_locked = data.stored_passengers_locked
            self._ship_name = data.stored_ship_name
            self._rescue_plane = data.stored_rescue_plane or false
            self._remove = data.remove or false

            local custom_data = data.stored_vehicle_custom_data or nil
            if custom_data then
                self._vehicle_custom_data = custom_data
            else
                -- o macete aqui eh inicializar mesmo que não exista no escopo da entity
                self._vehicle_custom_data = {} --initialize it
            end

            --minetest.debug("loaded: ", self._energy)
            local properties = self.object:get_properties()
            properties.infotext = (data.stored_owner or "") .. " nice airship"
            self.object:set_properties(properties)
            if self._remove == true then
                airutils.destroy_inventory(self)
                self.object:remove()
                --ap_airship.destroy(self)
                return
            end
        end

        local colstr = ap_airship.colors[self.color]
        if not colstr then
            colstr = "blue"
            self.color = colstr
        end

        ap_airship.paint(self, self.color)
        ap_airship.paint2(self, self.color2)
        local pos = self.object:get_pos()

        --cabin collider
        self._cabin=minetest.add_entity(pos,'ap_airship:ent_collider')
        self._cabin:set_attach(self.object,'',{x=0,y=-28,z=118},{x=0,y=0,z=0})
        self._cabin2=minetest.add_entity(pos,'ap_airship:ent_collider')
        self._cabin2:set_attach(self.object,'',{x=0,y=-28,z=158},{x=0,y=0,z=0})

        --passengers positions
        self._passenger_is_sit = ap_airship.copy_vector({})
        self._passengers_base = ap_airship.copy_vector({})
        self._passengers_base_pos = ap_airship.copy_vector({})
        for i = 1,ap_airship.max_pos,1 
        do
            self._passenger_is_sit[i] = 0
            self._passengers_base_pos[i] = ap_airship.copy_vector(ap_airship.passenger_pos[i])
            self._passengers_base[i]=minetest.add_entity(pos,'ap_airship:stand_base')
            self._passengers_base[i]:set_attach(self.object,'',self._passengers_base_pos[i],{x=0,y=0,z=0})
        end

        --constrols interactors
        self._control_interactor=minetest.add_entity(pos,'ap_airship:control_interactor')
        self._control_interactor:set_attach(self.object,'',{x=0,y=-28,z=175},{x=0,y=0,z=0})
        self._cabin_interactor=minetest.add_entity(pos,'ap_airship:cabin_interactor')
        self._cabin_interactor:set_attach(self.object,'',{x=-7,y=-28,z=115},{x=0,y=0,z=0})
        self._cabin_interactor=minetest.add_entity(pos,'ap_airship:exit_interactor')
        self._cabin_interactor:set_attach(self.object,'',{x=0,y=0,z=-120},{x=0,y=0,z=0})

        --chairs
        self._chairs_pos = ap_airship.copy_vector({
            [1]={x=-8.17622,y=-29,z=147}, [2]={x=8.17622,y=-29,z=147}, [3]={x=-8.17622,y=-29,z=135}, [4]={x=8.17622,y=-29,z=135}, [5]={x=8.17622,y=-29,z=123},
            [6]={x=20.176,y=0,z=84.2029}, [7]={x=10.176,y=0,z=84.2029}, [8]={x=20.176,y=0,z=63.005}, [9]={x=10.176,y=0,z=63.005},
            [10]={x=-20.176,y=0,z=84.2029}, [11]={x=-10.176,y=0,z=84.2029}, [12]={x=-20.176,y=0,z=63.005}, [13]={x=-10.176,y=0,z=63.005},
            [14]={x=20.176,y=0,z=39.2029}, [15]={x=10.176,y=0,z=39.2029}, [16]={x=20.176,y=0,z=18.005}, [17]={x=10.176,y=0,z=18.005},
            [18]={x=-20.176,y=0,z=39.2029}, [19]={x=-10.176,y=0,z=39.2029}, [20]={x=-20.176,y=0,z=18.005}, [21]={x=-10.176,y=0,z=18.005},})
        self._chairs = ap_airship.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil, [6]=nil, [7]=nil, [8]=nil, [9]=nil, [10]=nil,
                        [11]=nil, [12]=nil, [13]=nil, [14]=nil, [15]=nil, [16]=nil, [17]=nil, [18]=nil, [19]=nil, [20]=nil, [21]=nil})

        for i = 1,ap_airship.max_seats,1 
        do
            self._chairs[i] = minetest.add_entity(pos,'ap_airship:chair_interactor')
            self._chairs[i]:set_attach(self.object,'',self._chairs_pos[i],{x=0,y=0,z=0})
        end

        --animation load - stoped
        self.object:set_animation({x = 1, y = 47}, 0, 0, true)

        self.object:set_bone_position("low_rudder_a", {x=0,y=0,z=-40}, {x=-5.35,y=0,z=0})

        self.object:set_armor_groups({immortal=1})

        airutils.actfunc(self, staticdata, dtime_s)

        self.object:set_armor_groups({immortal=1})        

		local inv = minetest.get_inventory({type = "detached", name = self._inv_id})
		-- if the game was closed the inventories have to be made anew, instead of just reattached
		if not inv then
            airutils.create_inventory(self, ap_airship.trunk_slots)
		else
		    self.inv = inv
        end

        ap_airship.engine_step(self, 0)
        airutils.restore_external_attach(self)
    end,

    on_step = function(self,dtime,colinfo)
	    self.dtime = math.min(dtime,0.2)
	    self.colinfo = colinfo
	    self.height = airutils.get_box_height(self)
	    
    --  physics comes first
	    local vel = self.object:get_velocity()
	    
	    if colinfo then 
		    self.isonground = colinfo.touching_ground
	    end
	    
	    self:physics()

	    if self.logic then
		    self:logic()
	    end
	    
	    self.lastvelocity = self.object:get_velocity()
	    self.time_total=(self.time_total or 0)+self.dtime
    end,
    logic = function(self)
        
        local accel_y = self.object:get_acceleration().y
        local rotation = self.object:get_rotation()
        local yaw = rotation.y
        local newyaw=yaw
        local pitch = rotation.x
        local newpitch = pitch
        local roll = rotation.z

        local hull_direction = minetest.yaw_to_dir(yaw)
        local nhdir = {x=hull_direction.z,y=0,z=-hull_direction.x}        -- lateral unit vector
        local velocity = self.object:get_velocity()
        local curr_pos = self.object:get_pos()
        local wind_speed = airutils.get_wind(curr_pos, 0.15)
        
        local longit_speed = ap_airship.dot(velocity,hull_direction)
        
        self._longit_speed = longit_speed --for anchor verify
        local relative_longit_speed = ap_airship.dot(vector.add(velocity, wind_speed), hull_direction)
        self._relative_longit_speed = relative_longit_speed
        
        local longit_drag = vector.multiply(hull_direction,relative_longit_speed*
                relative_longit_speed*LONGIT_DRAG_FACTOR*-1*ap_airship.sign(relative_longit_speed))
        local later_speed = ap_airship.dot(velocity,nhdir)
        local later_drag = vector.multiply(nhdir,later_speed*later_speed*
                LATER_DRAG_FACTOR*-1*ap_airship.sign(later_speed))
        local accel = vector.add(longit_drag,later_drag)

        self._last_pos = curr_pos
        self.object:move_to(curr_pos)

        --minetest.chat_send_all(self._energy)
        --local node_bellow = airutils.nodeatpos(airutils.pos_shift(curr_pos,{y=-2.8}))
        --[[local is_flying = true
        if node_bellow and node_bellow.drawtype ~= 'airlike' then is_flying = false end]]--

        local is_attached = false
        local player = nil
        if self.driver_name then
            player = minetest.get_player_by_name(self.driver_name)
            
            if player then
                is_attached = ap_airship.checkAttach(self, player)
            end
        end

        if self.owner == "" then return end
        --[[if relative_longit_speed == 0 and is_flying == false and is_attached == false and self._engine_running == false then
            self.object:move_to(curr_pos)
            --self.object:set_acceleration({x=0,y=airutils.gravity,z=0})
            return
        end]]--

        --detect collision
        ap_airship.testDamage(self, velocity, curr_pos)

        accel = ap_airship.control(self, self.dtime, hull_direction, relative_longit_speed, accel) or velocity

        --get disconnected players
        ap_airship.rescueConnectionFailedPassengers(self)

        local turn_rate = math.rad(9)
        newyaw = yaw + self.dtime*(1 - 1 / (math.abs(relative_longit_speed) + 1)) *
            self._rudder_angle / 30 * turn_rate * ap_airship.sign(relative_longit_speed)

        ap_airship.engine_step(self, accel)
        
        --roll adjust
        ---------------------------------
        local sdir = minetest.yaw_to_dir(newyaw)
        local snormal = {x=sdir.z,y=0,z=-sdir.x}    -- rightside, dot is negative
        local prsr = ap_airship.dot(snormal,nhdir)
        local rollfactor = -4
        local newroll = 0
        if self._last_roll ~= nil then newroll = self._last_roll end
        --oscilation when stoped
        if relative_longit_speed == 0 then
            local time_correction = (self.dtime/ap_airship.ideal_step)
            --stoped
            if self._roll_state == nil then
                self._roll_state = math.floor(math.random(-1,1))
                if self._roll_state == 0 then self._roll_state = 1 end
                self._last_roll = newroll
            end
            if math.deg(newroll) >= 1 and self._roll_state == 1 then
                self._roll_state = -1
            end
            if math.deg(newroll) <= -1 and self._roll_state == -1 then
                self._roll_state = 1
            end
            local roll_factor = (self._roll_state * 0.005) * time_correction
            self._last_roll = self._last_roll + math.rad(roll_factor)
        else
            --in movement
            self._roll_state = nil
            newroll = (prsr*math.rad(rollfactor))*later_speed
            self._last_roll = newroll
        end
        --minetest.chat_send_all('newroll: '.. newroll)
        ---------------------------------
        -- end roll
        
        local wind_yaw = minetest.dir_to_yaw(wind_speed)
        --minetest.chat_send_all("x: "..wind_speed.x.. " - z: "..wind_speed.z.." - yaw: "..math.deg(wind_yaw).. " - orig: "..wind_yaw)

        if self.anchored == false and self.isonground == false then
            accel = vector.add(accel, wind_speed)
        else
            accel = vector.new()
        end
        accel.y = accel_y

        newpitch = velocity.y * math.rad(1.5) * (relative_longit_speed/3)

		local noded = airutils.nodeatpos(airutils.pos_shift(curr_pos,{y=-4.5}))
	    if (noded and noded.drawtype ~= 'airlike') or self.isonground then
            newpitch = 0
        end

        self.object:set_acceleration(accel)
        self.object:set_rotation({x=newpitch,y=newyaw,z=newroll})

        local compass_angle = newyaw
        local rem_obj = self.object:get_attach()
        if rem_obj then
            compass_angle = rem_obj:get_rotation().y
        end
        local N_angle = math.deg(compass_angle)
        local S_angle = N_angle + 180

        self.object:set_bone_position("elevator", {x=0,y=60.5919,z=-284.79}, {x=0,y=newpitch,z=0})
        self.object:set_bone_position("rudder", {x=0,y=60.5919,z=-284.79}, {x=0,y=self._rudder_angle-180,z=0})
        self.object:set_bone_position("timao", {x=0,y=-22.562,z=176.018}, {x=0,y=0,z=self._rudder_angle*8})
        self.object:set_bone_position("compass_axis", {x=0,y=-21.8,z=178.757}, {x=0, y=S_angle, z=0})

		noded = airutils.nodeatpos(airutils.pos_shift(curr_pos,{y=-4.5}))
	    if (noded and noded.drawtype ~= 'airlike') or self.isonground then
            self.object:set_bone_position("door", {x=0,y=-13.1266,z=54.1922}, {x=-28,y=0,z=0})
        else
            self.object:set_bone_position("door", {x=0,y=-13.1266,z=54.1922}, {x=0,y=0,z=0})

            if self._rescue_plane then
                ap_airship.timed_anchor_entity(self, curr_pos, yaw, 3, self.dtime)
            end
        end

        --saves last velocy for collision detection (abrupt stop)
        self._last_vel = self.object:get_velocity()
        self._last_accell = accel

        ap_airship.move_persons(self)
    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        if not puncher or not puncher:is_player() then
            return
        end
        local is_admin = false
        is_admin = minetest.check_player_privs(puncher, {server=true})
		local name = puncher:get_player_name()
        if self.owner == nil then
            self.owner = name
        end
            
        if self.driver_name and self.driver_name ~= name then
            -- do not allow other players to remove the object while there is a driver
            return
        end
        
        local is_attached = ap_airship.checkAttach(self, puncher)

        local itmstck=puncher:get_wielded_item()
        local item_name = ""
        if itmstck then item_name = itmstck:get_name() end

        if is_attached == true then
            --refuel
            ap_airship.load_fuel(self, puncher)
        end
        if self.owner and self.owner ~= name and self.owner ~= "" then
            if is_admin == false then return end
        end

        -- deal with painting or destroying
        if itmstck then
            local _,indx = item_name:find('dye:')
            if indx then

                --lets paint!!!!
                local color = item_name:sub(indx+1)
                local colstr = ap_airship.colors[color]
                --minetest.chat_send_all(color ..' '.. dump(colstr))
                if colstr and (name == self.owner or minetest.check_player_privs(puncher, {protection_bypass=true})) then
                    local ctrl = puncher:get_player_control()
                    if ctrl.aux1 then
                        ap_airship.paint2(self, colstr)
                    else
                        ap_airship.paint(self, colstr)
                    end
                    itmstck:set_count(itmstck:get_count()-1)
                    puncher:set_wielded_item(itmstck)
                end
                -- end painting
            end
        end

        if is_attached == false then
            local i = 0
            local has_passengers = false
            for i = ap_airship.max_pos,1,-1 
            do 
                if self._passengers[i] ~= nil then
                    has_passengers = true
                    break
                end
            end


            if not has_passengers and toolcaps and toolcaps.damage_groups and
                    toolcaps.groupcaps and toolcaps.groupcaps.choppy then

                local is_empty = true --[[false
                local inventory = airutils.get_inventory(self)
                if inventory then
                    if inventory:is_empty("main") then is_empty = true end
                end]]--

                --airutils.make_sound(self,'hit')
                if is_empty == true then
                    self.hp = self.hp - 10
                    minetest.sound_play("ap_airship_collision", {
                        object = self.object,
                        max_hear_distance = 5,
                        gain = 1.0,
                        fade = 0.0,
                        pitch = 1.0,
                    })
                end
            end

            if self.hp <= 0 then
                ap_airship.destroy(self, false)
            end

        end
        
    end,

    on_rightclick = right_click_function,
})
