Minetest 5.4 mod: Airship
========================================

This mod implements an airship for minetest. This airship is affected by the wind. The wind better works
with Climate API (and with climate API you can stop it using /set_wind 0 0 )
THIS IS HIGHLY EXPERIMENTAL AND HAVE A LOT OF MISSING FEATURES. AND I KNOW IT
THE COLLISION SYSTEM IS VERY RUDIMENTARY
The fuel system isn't exists yet, so I don't recomend giving it to players yet if you put it into a server

Shortcuts:

forward and backward while in drive position: controls the power lever
left and right while in drive position: controls the direction
jump and sneak: controls the up and down movement

- right click into the external stair to enter it
- E + backward while in drive position: the machine does backward
- E + foward while in drive position: extra power
- right click into drive wheel to activate pilot menu
- right click into the internal ladders to go out
- right click into any seat to sit your player
- the anchor only works when the airship is near stoped

Remembering AGAIN, it is affected by winds, so it will need patience to learn to control

Tip:
Drive it gently.
The captain can leave the drive position to walk too
If a player goes timeout or logoff in flight, the airship will "rescue" him if no other player
enter it, so is a good idea wait the friend at a secure place far from anyone who
wants to enter the airship.

Special functions:
/external_attach_menu
- it opens the menu to attach a plane into the airship (who watched Indiana Jones and The Last Cruzade
  will understand)
  to access the plane during the flight, go to the ladder at the end of the airship and right click it
  to release the plane during the flight, use /remove_hook (BEWARE: the airship have to be moving fast
  and the plane power have to be at 1/4 to avoid collision and death (for the plane pilot))
There is an option on pilot menu to activate the rescue mode. So if a plane (Supercub, Camel or Albatroz)
wait bellow the ship belly IN FLIGHT, it will be automatically hooked after 3 seconds


Know issues:
The walk movement inside the ship is affected by server lag, because the lack of
an interpolation method on attach function.
  
License of source code:
MIT (see file LICENSE) 

License of media (textures and sounds):
---------------------------------------
Airship model and textures by APercy. CC BY-SA 3.0

Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
Copyright (C) 2022 Alexsandro Percy (APercy) <alexsandro.percy@gmail.com>

You are free to:
Share — copy and redistribute the material in any medium or format.
Adapt — remix, transform, and build upon the material for any purpose, even commercially.
The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:

Attribution — You must give appropriate credit, provide a link to the license, and
indicate if changes were made. You may do so in any reasonable manner, but not in any way
that suggests the licensor endorses you or your use.

ShareAlike — If you remix, transform, or build upon the material, you must distribute
your contributions under the same license as the original.

No additional restrictions — You may not apply legal terms or technological measures that
legally restrict others from doing anything the license permits.

Notices:

You do not have to comply with the license for elements of the material in the public
domain or where your use is permitted by an applicable exception or limitation.
No warranties are given. The license may not give you all of the permissions necessary
for your intended use. For example, other rights such as publicity, privacy, or moral
rights may limit how you use the material.

For more details:
http://creativecommons.org/licenses/by-sa/3.0/

