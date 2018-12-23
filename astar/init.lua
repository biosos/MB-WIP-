astar = {}
astar.modname = minetest.get_current_modname()
astar.modpath = minetest.get_modpath(astar.modname)
astar.handlers = {}

dofile(astar.modpath .. DIR_DELIM .. "Heap.lua")
dofile(astar.modpath .. DIR_DELIM .. "MapscannerBasicGround.lua")
dofile(astar.modpath .. DIR_DELIM .. "Astar.lua")


--temp
dofile(astar.modpath .. DIR_DELIM .. "MapscannerBasicGround.lua")
--end