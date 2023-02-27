--------------
-- Manual --
--------------

function ap_airship.manual_formspec(name)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[6,6]"
	}, "")

	basic_form = basic_form.."button[1,1.0;4,1;short;Shortcuts]"
	basic_form = basic_form.."button[1,2.5;4,1;fuel;Refueling]"
	basic_form = basic_form.."button[1,4.0;4,1;share;Sharing]"

    minetest.show_formspec(name, "ap_airship:manual_main", basic_form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "ap_airship:manual_main" then
        local formspec_color = "#44444466"
		if fields.short then
			local text = {
				"Shortcuts \n\n",
                "* Right click: enter in / acess the internal menu \n",
                "* Punch with dye to paint the primary color\n",
                "* Punch a dye, but holding Aux (E) key to change the secondary color.\n",
                "* To change the airship logo, call the command \""..core.colorize('#ffff00', "/airship_logo").."\".\n",
                "* Forward or backward while in drive position: controls the power lever \n",
                "* Left or right while in drive position: controls the direction \n",
                "* Jump and sneak: controls the up and down movement \n",
                "* Aux (E) + right click while inside: acess inventory \n",
                "* Aux (E) + backward while in drive position: the machine does backward \n",
                "* Aux (E) + foward while in drive position: extra power \n"
			}
			local shortcut_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
                "no_prepend[]",
                "bgcolor["..formspec_color..";false]",
				"label[1.0,2.0;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "ap_airship:manual_shortcut", shortcut_form)
		end
		if fields.fuel then
			local text = {
				"Fuel \n\n",
				"To fly it, it is necessary to provide some items, such as fuel to be burned and \n",
				"water for the boiler. The fuel can be coal, coal block or wood. To supply it, \n",
				"be on board and punch the necessary items on the airship.\n",
                "There is another way to load water to the boiler: if it is landed on water, it can load \n",
				"it through the menu. But the current pressure will be lost. \n"
			}
			local fuel_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
                "no_prepend[]",
                "bgcolor["..formspec_color..";false]",
				"label[1.0,2.0;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "ap_airship:fuel", fuel_form)
		end
		if fields.share then
			local text = {
				"Sharing \n\n",
                "This vehicle was made to be shared with a team. So the owner can set more users to  \n",
                "operate it. Inside the airship, just use the command \""..core.colorize('#ffff00', "/airship_share <name>").."\" \n",
                "To remove someone from the sharing, \""..core.colorize('#ffff00', "/airship_remove <name>").."\" \n",
                "To list the owners, \""..core.colorize('#ffff00', "/airship_list").."\" \n",
                "Is possible to lock the airship access, so only the owners can enter: \""..core.colorize('#ffff00', "/airship_lock true").."\" \n",
                "To let anyone enter, \""..core.colorize('#ffff00', "/airship_lock false").."\" \n",
                "All shared owners can access the airship inventory"
			}
			local tips_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
                "no_prepend[]",
                "bgcolor["..formspec_color..";false]",
				"label[1,2;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "ap_airship:share", tips_form)
		end
	end
end)

minetest.register_chatcommand("airship_manual", {
	params = "",
	description = "Airship manual",
	func = function(name, param)
        ap_airship.manual_formspec(name)
	end
})
