ap_airship={}
ap_airship.gravity = tonumber(minetest.settings:get("movement_gravity")) or 9.8
ap_airship.trunk_slots = 50
ap_airship.fuel = {['biofuel:biofuel'] = {amount=1},['biofuel:bottle_fuel'] = {amount=1},
        ['biofuel:phial_fuel'] = {amount=0.25}, ['biofuel:fuel_can'] = {amount=10}}
ap_airship.ideal_step = 0.02
ap_airship.rudder_limit = 30
ap_airship.iddle_rotation = 50
ap_airship.max_engine_acc = 1.5
ap_airship.max_speed = 8
ap_airship.max_pos = 12
ap_airship.max_seats = 21
ap_airship.pilot_base_pos = {x=0.0,y=-29,z=170}
ap_airship.passenger_pos = {
    [1] = {x=0.0,y=0,z=60},
    [2] = {x=-32,y=0,z=20},
    [3] = {x=32,y=0,z=20},
    [4] = {x=-32,y=0,z=80},
    [5] = {x=32,y=0,z=80},
    [6] = {x=0.0,y=0,z=50},
    [7] = {x=-32,y=0,z=30},
    [8] = {x=32,y=0,z=30},
    [9] = {x=-32,y=0,z=70},
    [10] = {x=32,y=0,z=70},
    [11] = {x=0.0,y=0,z=40},
    [12] = {x=0.0,y=0,z=30},
    }

ap_airship.canvas_texture = "wool_white.png^[colorize:#f4e7c1:128"
ap_airship.grey_texture = "ap_airship_base.png^[colorize:#535c5c:128"
ap_airship.white_texture = "ap_airship_base.png^[colorize:#a3acac:128"
ap_airship.metal_texture = "ap_airship_metal.png"
ap_airship.black_texture = "ap_airship_base.png^[colorize:#030303:200"
ap_airship.rotor_texture = "ap_airship_helice.png"
ap_airship.textures = {
            ap_airship.grey_texture, --"ap_airship_painting.png", --balao
            ap_airship.metal_texture, --ponteira nariz
            "airutils_name_canvas.png",
            "ap_airship_brown.png", --mobilia
            ap_airship.metal_texture, --mobilia
            ap_airship.black_texture, -- corpo da bussola
            ap_airship.metal_texture, -- indicador bussola
            ap_airship.grey_texture, --"ap_airship_painting.png", --empenagem
            ap_airship.metal_texture, --timao
            ap_airship.black_texture, --timao
            "ap_airship_compass.png", --bussola
            "ap_airship_sup_eng.png", --suporte motores
            "ap_airship_helice.png", --helice
            ap_airship.black_texture, --eixo helice
            ap_airship.grey_texture, --interior cabine
            "default_ladder_steel.png", --escada
            ap_airship.white_texture, --interior cabine 2
            "ap_airship_glass_2.png", --vidros do deck superior
            ap_airship.grey_texture, -- "ap_airship_painting.png", --motor
            ap_airship.grey_texture, --"ap_airship_painting.png", --cabine
            "ap_airship_glass.png", --janelas
            ap_airship.black_texture, --piso
            "ap_airship_alpha_logo.png", --logo
            ap_airship.metal_texture,
            "wool_red.png",
        }

ap_airship.colors ={
    black='black',
    blue='blue',
    brown='brown',
    cyan='cyan',
    dark_green='dark_green',
    dark_grey='dark_grey',
    green='green',
    grey='grey',
    magenta='magenta',
    orange='orange',
    pink='pink',
    red='red',
    violet='violet',
    white='white',
    yellow='yellow',
}

dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "utilities.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "control.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "fuel_management.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "engine_management.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "custom_physics.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "hud.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "entities.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "forms.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "manual.lua")
dofile(minetest.get_modpath("ap_airship") .. DIR_DELIM .. "walk_map.lua")

--
-- helpers and co.
--

function ap_airship.get_hipotenuse_value(point1, point2)
    return math.sqrt((point1.x - point2.x) ^ 2 + (point1.y - point2.y) ^ 2 + (point1.z - point2.z) ^ 2)
end

function ap_airship.dot(v1,v2)
    return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z
end

function ap_airship.sign(n)
    return n>=0 and 1 or -1
end

function ap_airship.minmax(v,m)
    return math.min(math.abs(v),m)*ap_airship.sign(v)
end


minetest.register_privilege("ap_airship_anchor", {
    description = "The player can anchor the airship anywhere in any speed",
    give_to_singleplayer = false
})

-----------
-- items
-----------

-- airship
minetest.register_craftitem("ap_airship:airship", {
	description = "Airship",
	inventory_image = "ap_airship_icon.png",
    liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
        
        local pointed_pos = pointed_thing.under
        --local node_below = minetest.get_node(pointed_pos).name
        --local nodedef = minetest.registered_nodes[node_below]
        
		pointed_pos.y=pointed_pos.y+4
		local airship = minetest.add_entity(pointed_pos, "ap_airship:airship")
		if airship and placer then
            local ent = airship:get_luaentity()
            ent._passengers = ap_airship.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil, [6]=nil, [7]=nil, [8]=nil, [9]=nil, [10]=nil, [11]=nil, [12]=nil})
            --minetest.chat_send_all('passengers: '.. dump(ent._passengers))
            local owner = placer:get_player_name()
            ent.owner = owner
			airship:set_yaw(placer:get_look_horizontal())
			itemstack:take_item()
            airutils.create_inventory(ent, ap_airship.trunk_slots, owner)

            local properties = ent.object:get_properties()
            properties.infotext = owner .. " nice airship"
            airship:set_properties(properties)
            --ap_airship.attach_pax(ent, placer)
		end

		return itemstack
	end,
})


--
-- crafting
--

if not minetest.settings:get_bool('ap_airship.disable_craftitems') then
    --[[minetest.register_craft({
	    output = "ap_airship:cylinder_part",
	    recipe = {
		    {"default:stick", "wool:white", "default:stick"},
		    {"wool:white", "group:wood", "wool:white"},
            {"default:stick", "wool:white", "default:stick"},
	    }
    })

    minetest.register_craft({
	    output = "ap_airship:cylinder",
	    recipe = {
		    {"ap_airship:cylinder_part", "ap_airship:cylinder_part", "ap_airship:cylinder_part"},
	    }
    })

    minetest.register_craft({
	    output = "ap_airship:rotor",
	    recipe = {
		    {"wool:white", "default:stick", ""},
		    {"wool:white", "default:stick", "default:steelblock"},
		    {"wool:white", "default:stick", ""},
	    }
    })

    minetest.register_craft({
	    output = "ap_airship:boiler",
	    recipe = {
		    {"default:steel_ingot","default:steel_ingot"},
		    {"default:steelblock","default:steel_ingot",},
		    {"default:steelblock","default:steel_ingot"},
	    }
    })

    minetest.register_craft({
	    output = "ap_airship:boat",
	    recipe = {
		    {"group:wood", "group:wood", "ap_airship:rotor"},
		    {"group:wood", "ap_airship:boiler", "group:wood"},
		    {"group:wood", "group:wood", "ap_airship:rotor"},
	    }
    })

	minetest.register_craft({
		output = "ap_airship:airship",
		recipe = {
			{"ap_airship:cylinder",},
			{"ap_airship:boat",},
		}
	})]]--

    -- cylinder section
    --[[minetest.register_craftitem("ap_airship:cylinder_part",{
	    description = "ap_airship cylinder section",
	    inventory_image = "ap_airship_cylinder_part.png",
    })

    -- cylinder
    minetest.register_craftitem("ap_airship:cylinder",{
	    description = "ap_airship cylinder",
	    inventory_image = "ap_airship_cylinder.png",
    })

    -- boiler
    minetest.register_craftitem("ap_airship:boiler",{
	    description = "ap_airship boiler",
	    inventory_image = "ap_airship_boiler.png",
    })

    -- boiler
    minetest.register_craftitem("ap_airship:rotor",{
	    description = "ap_airship rotor",
	    inventory_image = "ap_airship_rotor.png",
    })

    -- fuselage
    minetest.register_craftitem("ap_airship:boat",{
	    description = "ap_airship fuselage",
	    inventory_image = "ap_airship_boat.png",
    })]]--
end

