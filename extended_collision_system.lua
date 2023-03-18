

function ap_airship.eval_interception(initial_pos, end_pos)
	local cast = minetest.raycast(initial_pos, end_pos, true, false)
	local thing = cast:next()
	while thing do
		if thing.type == "node" then
            local pos = thing.intersection_point
            if pos then
                local nodename = minetest.get_node(thing.under).name
                local drawtype = get_nodedef_field(nodename, "drawtype")
                if drawtype ~= "plantlike" then
                    return true
                end
            end
        end
        thing = cast:next()
    end
    return false
end

local function get_target_distance(pos, target)
    local x1, y1 = pos.x, pos.z
    local x2, y2 = target.x, target.z
    local distance = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)

    return distance
end

--retorna uma posição de outra derivando de distancia e direção
local function shift_target_by_direction(origin, direction, distance)
    local shifted_target = {x=0,y=origin.y,z=0}
    direction = direction / 360
    direction = ((direction - math.floor(direction))*360)
    local direction_rad = math.rad(direction)
    shifted_target = {x=math.cos(direction_rad)*distance,y=origin.y,z=math.sin(direction_rad)*distance}
    shifted_target.x = origin.x + shifted_target.x
    shifted_target.z = origin.z + shifted_target.z
    --airship_ap.print_l("origin x: "..origin.x.." - z: "..origin.z.." - target x: "..shifted_target.x.." - z: "..shifted_target.z.." - yaw: "..direction.." - target distance: "..distance)
    return shifted_target
end

