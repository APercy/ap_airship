--
-- fuel
--
ap_airship.MAX_FUEL = minetest.settings:get("ap_airship_max_fuel") or 99
ap_airship.FUEL_CONSUMPTION = minetest.settings:get("ap_airship_fuel_consumption") or 6000

function ap_airship.contains(table, val)
    for k,v in pairs(table) do
        if k == val then
            return v
        end
    end
    return false
end

function ap_airship.load_fuel(self, player)
    local inv = player:get_inventory()

    local itmstck=player:get_wielded_item()
    local item_name = ""
    if itmstck then item_name = itmstck:get_name() end

    local grp_wood = minetest.get_item_group(item_name, "wood")
    local grp_tree = minetest.get_item_group(item_name, "tree")
    if grp_wood == 1 or grp_tree == 1 then
        local stack = ItemStack(item_name .. " 1")

        if self._energy < ap_airship.MAX_FUEL then
            inv:remove_item("main", stack)
            local amount = 1
            if grp_tree == 1 then amount = 4 end
            self._energy = self._energy + amount
            if self._energy > ap_airship.MAX_FUEL then self._energy = ap_airship.MAX_FUEL end
        end
        return true
    end

    --minetest.chat_send_all("fuel: ".. dump(item_name))
    local fuel = ap_airship.contains(ap_airship.fuel, item_name)
    if fuel then
        local stack = ItemStack(item_name .. " 1")

        if self._energy < ap_airship.MAX_FUEL then
            inv:remove_item("main", stack)
            self._energy = self._energy + fuel.amount
            if self._energy > ap_airship.MAX_FUEL then self._energy = ap_airship.MAX_FUEL end
            --minetest.chat_send_all(self.energy)

            --local energy_indicator_angle = ap_airship.get_pointer_angle(self._energy, ap_airship.MAX_FUEL)
        end
        
        return true
    end

    return false
end


