local startingboss = {}
local startingdng = {}
local playertracker = {}
local hub = {}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


local function myremove(tbl, key)
    tbl[key]=nil
end

local function myinsert(tbl,val)
    local i =1
    while tbl[i] do
        i=i+1
    end

    tbl[i] = val
    playertracker[val]={table = tbl, pos=i}
end

local function new(player)
player:set_attribute("progresse",1)
end

local function placer(startpos, rooms, corridor)
    local placepos, endpos = nil , startpos
    local i = 1

    local function func(room)
        placepos = vector.add(endpos, room.placepos)
        endpos = vector.add(endpos, room.endpos)

        minetest.place_schematic(placepos, room.path, true)
    end

    return function()
        if not rooms[i] then return false end

        func(rooms[i])
        func(corridor)
        i=i+1
		return true
    end
end



local function create_startingdng(offset)
	local stdr=minetest.get_dir_list(modpath..DIR_DELIM.."schems_dng", false)
	local actuallpos={x=0,y=1000,z=100*offset}
	local startingdngcreate={}
	local rooms={}
	local corridorpath = modpath..DIR_DELIM.."schems_dng"..DIR_DELIM
				.."data"..DIR_DELIM.."corridor.mts"
	table.insert(startingdngcreate, "start.mts")
	local i = 1
	while stdr[i] and stdr[i] ~=  "start.mts" do
		i = i + 1
	end	
	table.remove(stdr,i)
	
	for i=1,math.min(#stdr,3) do
		local r=math.random(1,#stdr)
		local v=stdr[r]
		table.remove(stdr,r)
		table.insert(startingdngcreate, v)
	end	
	
	for i,path in ipairs(startingdngcreate) do
		rooms[i]={}
		rooms[i].path=modpath..DIR_DELIM.."schems_dng"..DIR_DELIM..path
		
		path=string.sub(path,1,-4) .. "txt"
		local filepath=modpath..DIR_DELIM.."schems_dng"..DIR_DELIM
				.."data"..DIR_DELIM..path
		
		local file=io.open(filepath)
		rooms[i].placepos=minetest.deserialize(assert(file:read("*l")))
		rooms[i].endpos=minetest.deserialize(assert(file:read("*l")))
		size=minetest.deserialize(assert(file:read("*l")))
		file:close()
		
		rooms[i].endpos.x = rooms[i].endpos.x + size.x
	end
	
	corridor={path=corridorpath,placepos=vector.new(0,0,0),endpos=vector.new(10,4,0)}
	
	local iter = placer(actuallpos,rooms,corridor)
	while iter() do
	end
end

local function leave(player)
	local name = player:get_player_name()
	local dng = playertracker[name]["table"]
	local pos = playertracker[name]["pos"]
	dng[pos] =nil
	playertracker[name]=nil
end


local function  rejoin(player)
local prg = player:get_attribute("progresse")
local name = player:get_player_name()
player:setpos({x=0,y=2,z=0})
myinsert(hub, name)
	if(prg=="0") then
		myinsert(startingboss, name)
		local offset = playertracker[name]["pos"]
		local schempath = minetest.get_modpath(modname)..DIR_DELIM.."schems_boss"..DIR_DELIM.."stb2.mts"
		player:setpos({x=100*offset,y=-1000,z=50.5})
		player:set_look_vertical(0)
		player:set_look_horizontal(math.pi*1.5)
		minetest.place_schematic({x=(100*offset)-2,y=-1005,z=41}, schempath, true)
	elseif(prg=="1") then
		leave(player)
		myinsert(startingdng,name)
		local offset = playertracker[name]["pos"]
		create_startingdng(offset)
		player:setpos({x=0,y=1000.5,z=100*offset})
	end	

	end




minetest.register_chatcommand("abfrage",{
 func=function(name,param)
	local offset=tonumber(param) or 0
	local player=minetest.get_player_by_name("singleplayer")
	create_startingdng(offset)
	player:setpos({x=0,y=1000,z=100*offset+0.5})
	player:set_look_vertical(0)
	player:set_look_horizontal(math.pi*1.5)
	--[[local f=minetest.get_dir_list(modpath..DIR_DELIM.."schems_dng",false)
	local placepos={}
	minetest.chat_send_all(dump2(f))
		local filepath=modpath..DIR_DELIM.."schems_dng"..DIR_DELIM
				.."data"..DIR_DELIM.."room1.txt"
	placepos=minetest.deserialize(read_line(filepath,1))
	minetest.log(dump2(placepos))]]
	end,
})

minetest.register_on_newplayer(new) --Marks new player
minetest.register_on_joinplayer(rejoin) --Places player in the right area
minetest.register_on_leaveplayer(leave) --gets player out of system
