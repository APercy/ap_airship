ap_airship.PRESSURE_CONSUMPTION = 500

local adjust_variable = 500
local lost_power = (1/ap_airship.FUEL_CONSUMPTION)*adjust_variable
local gained_pressure = (2/ap_airship.FUEL_CONSUMPTION)*adjust_variable

ap_airship.boiler_min = 1
ap_airship.boiler_max = 310

function ap_airship.start_engine(self)
    -- sound
    --minetest.chat_send_all(dump(self.sound_handle_engine))
    if self.sound_handle_engine == nil and self._engine_running == true then
         self.object:set_animation_frame_speed(ap_airship.iddle_rotation)
        if self.object then
            self.sound_handle_engine = minetest.sound_play({name = "ap_airship_engine"},--"default_item_smoke"},
                {object = self.object, gain = 3.0,
                    pitch = 0.4,
                    max_hear_distance = 120,
                    loop = true,})
        end
    end
end

local function engines_step(self, accel)
    ap_airship.start_engine(self)
    ap_airship.engine_set_sound_and_animation(self)
end

local function furnace_step(self, accel)
    if self._energy > 0 and self._engine_running then
        local consumed_power = (1/ap_airship.FUEL_CONSUMPTION)
        --self._energy = self._energy - consumed_power; --removes energy
    end
end

function ap_airship.engine_step(self, accel)
    furnace_step(self, accel)
    engines_step(self, accel)

    if self.driver_name then
        local player = minetest.get_player_by_name(self.driver_name)

        local pressure = 0
        local coal = self._energy
        --minetest.chat_send_all(self._power_lever)
        ap_airship.update_hud(player, coal, 180, -pressure, self._power_lever)
    end
end

