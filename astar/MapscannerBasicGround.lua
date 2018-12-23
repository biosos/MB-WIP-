-- Lua Map Reader

--[[ params 
	basepos		-> 'lower left corner'
	size		-> size of the box
	mobsize 	-> {min: lower collisionbox of mob, max: analog}; values are int
	jumpheight
	fallheight
	roomid		-> unique!! identifier of box
	modifier	-> {move cost modifiers for different nodes}
	handlertype -> unique!! identifier of handler to use
	
	redefs		-> redefine nodes as solid/liquid/gas (0/1/2)
end params --]]

local basepos = vector.new(0,0,0)
local size = vector.new(20,20,20)
local mobsize = {vector.new(0,0,0), vector.new(0,1,0)}
local jumpheight = 1
local fallheight = 3
local roomid = "testroom1"
local modifier = {["default:water_source"] = 2, ["default:water_flowing"] = 2}
local handlertype = "groundPrescanV1"

local redefs = {}


-- set groups on nodes to make reading them in easier
local state,solid

for name,def in pairs(minetest.registered_nodes) do
	state = redefs[name] or ((def.walkable ~= false) and 0 or 2)
	solid = (state == 0) and 1 or nil
	minetest.override_item(name,{groups = {["state"] = state,["solid"] = solid}})
end

local oldregister = minetest.register_node

minetest.register_node = function(name, def)
	def.groups = def.groups or {}
	def.groups.state = redefs[name] or ((def.walkable ~= false) and 0 or 2)
	def.groups.solid = (def.groups.state == 0) and 1 or nil
	oldregister(name, def)
end

state,solid = nil,nil
--===============================================


-- functions to calculate id from pos and backwards
local function id(pos)
	local tid = pos.x + (pos.y * size.x) + (pos.z * (size.x * size.y))
	assert(tid < size.x * size.y * size.z, "id: id out of range: " .. tid)
	
	return tid
end

local function pos(id, relative)
	assert(id < size.x * size.y * size.z, "pos: id out of range: " .. id)

	local pos = {}
	
	pos.x = id % size.x
	pos.y = math.floor((id % (size.x * size.y)) / size.x)
	pos.z = math.floor(id / (size.x * size.y))
	
	return relative and pos or vector.add(basepos, pos)
end
--===============================================


-- custom iterator function to iterate over all positions inside the specified box
local function forxyz(tbasepos, tsize)
	tbasepos = tbasepos or vector.new(0,0,0)
	tsize = tsize or vector.new(0,0,0)
	
	local id = -1
	local x,y,z = -1,0,0
	local maxid = tsize.x * tsize.y * tsize.z
	
	return function()
		id = id +1
		if id < maxid then
			return id, pos(id)
		end
	end
end
--===============================================


-- functions we use later... redefine these if needed
local function mypcall(func, ...)
	local a,b = pcall(func, ...)
	return a and b
end

local function node_type(val) --val can be either pos or id
	assert(val, "nil was passed to node_type")
	local pos = tonumber(val) and pos(val) or val
	local nodename = minetest.get_node(pos).name
	
	return minetest.registered_nodes[nodename].groups.state
end

local function passable(val) --val can be either pos or id
	assert(val, "nil was passed to passable")
	local pos = tonumber(val) and pos(val) or val
	
	local minpos = vector.add(pos, mobsize[1])
	local maxpos = vector.add(pos, mobsize[2])
	
	return #minetest.find_nodes_in_area(minpos, maxpos, "group:solid") == 0
end

local function standable(val) --val can be either pos or id
	assert(val, "nil was passed to standable")
	local pos = tonumber(val) and pos(val) or val
	
	pos.y = pos.y + mobsize[1].y
	local posunder = vector.add(pos, vector.new(0,-1,0))
		
	return (node_type(posunder) == 0) or (node_type(posunder) == 1 and node_type(pos) == 1)
end

-- need to clean this up (but not soon...)
local function neighbours(val) --val can be either pos or id
	assert(val, "nil was passed to neighbours")
	local pos = tonumber(val) and pos(val) or val
	
	local result = {}
	
	local temp
	
	-- cardinal directions
	temp = vector.add(pos, vector.new(-1,0,0))
	if mypcall(standable, temp) then table.insert(result, id(temp)) end
	
	temp = vector.add(pos, vector.new(1,0,0))
	if mypcall(standable, temp) then table.insert(result, id(temp)) end
	
	temp = vector.add(pos, vector.new(0,0,-1))
	if mypcall(standable, temp) then table.insert(result, id(temp)) end
	
	temp = vector.add(pos, vector.new(0,0,1))
	if mypcall(standable, temp) then table.insert(result, id(temp)) end
	
	
	local temp2,temp3
	
	-- diagonal directions
	temp = vector.add(pos, vector.new(-1,0,-1))
	temp2 = vector.add(pos, vector.new(-1,0,0))
	temp3 = vector.add(pos, vector.new(0,0,-1))
	if mypcall(standable, temp) and mypcall(passable, temp2) and mypcall(passable, temp3) then table.insert(result, id(temp)) end
	
	temp = vector.add(pos, vector.new(-1,0,1))
	temp2 = vector.add(pos, vector.new(-1,0,0))
	temp3 = vector.add(pos, vector.new(0,0,1))
	if mypcall(standable, temp) and mypcall(passable, temp2) and mypcall(passable, temp3) then table.insert(result, id(temp)) end
	
	temp = vector.add(pos, vector.new(1,0,-1))
	temp2 = vector.add(pos, vector.new(1,0,0))
	temp3 = vector.add(pos, vector.new(0,0,-1))
	if mypcall(standable, temp) and mypcall(passable, temp2) and mypcall(passable, temp3) then table.insert(result, id(temp)) end
	
	temp = vector.add(pos, vector.new(1,0,1))
	temp2 = vector.add(pos, vector.new(1,0,0))
	temp3 = vector.add(pos, vector.new(0,0,1))
	if mypcall(standable, temp) and mypcall(passable, temp2) and mypcall(passable, temp3) then table.insert(result, id(temp)) end
	
	local temp4
	local minpos, maxpos
	
	-- jumping
	temp = pos
	temp2 = 1
	temp3 = true
	
	while temp3 and temp2 <= jumpheight do
		temp = vector.add(temp, vector.new(0,1,0))
		if mypcall(passable, temp) then
			minpos = vector.add(temp, vector.new(mobsize[1].x,0,0))
			
			maxpos = vector.new(math.max(temp.x, minpos.x), math.max(temp.y, minpos.y), math.max(temp.z, minpos.z))
			minpos = vector.new(math.min(temp.x, minpos.x), math.min(temp.y, minpos.y), math.min(temp.z, minpos.z))
			
			minpos = vector.add(minpos, mobsize[1])
			maxpos = vector.add(maxpos, mobsize[2])
			
			if #minetest.find_nodes_in_area(minpos, maxpos, "group:solid") == 0 then
				maxpos = vector.subtract(maxpos, mobsize[2])
				if mypcall(standable, maxpos) then
					temp3 = false
					table.insert(result, id(maxpos))
				end
			end
			temp2 = temp2 +1
		else
			temp3 = false
		end
	end
	
	temp = pos
	temp2 = 1
	temp3 = true
	
	while temp3 and temp2 <= jumpheight do
		temp = vector.add(temp, vector.new(0,1,0))
		if mypcall(passable, temp) then
			minpos = vector.add(temp, vector.new(mobsize[2].x,0,0))
			
			maxpos = vector.new(math.max(temp.x, minpos.x), math.max(temp.y, minpos.y), math.max(temp.z, minpos.z))
			minpos = vector.new(math.min(temp.x, minpos.x), math.min(temp.y, minpos.y), math.min(temp.z, minpos.z))
			
			minpos = vector.add(minpos, mobsize[1])
			maxpos = vector.add(maxpos, mobsize[2])
			
			if #minetest.find_nodes_in_area(minpos, maxpos, "group:solid") == 0 then
				maxpos = vector.subtract(maxpos, mobsize[2])
				if mypcall(standable, maxpos) then
					temp3 = false
					table.insert(result, id(maxpos))
				end
			end
			temp2 = temp2 +1
		else
			temp3 = false
		end
	end
	
	temp = pos
	temp2 = 1
	temp3 = true
	
	while temp3 and temp2 <= jumpheight do
		temp = vector.add(temp, vector.new(0,1,0))
		if mypcall(passable, temp) then
			minpos = vector.add(temp, vector.new(0,0,mobsize[1].z))
			
			maxpos = vector.new(math.max(temp.x, minpos.x), math.max(temp.y, minpos.y), math.max(temp.z, minpos.z))
			minpos = vector.new(math.min(temp.x, minpos.x), math.min(temp.y, minpos.y), math.min(temp.z, minpos.z))
			
			minpos = vector.add(minpos, mobsize[1])
			maxpos = vector.add(maxpos, mobsize[2])
			
			if #minetest.find_nodes_in_area(minpos, maxpos, "group:solid") == 0 then
				maxpos = vector.subtract(maxpos, mobsize[2])
				if mypcall(standable, maxpos) then
					temp3 = false
					table.insert(result, id(maxpos))
				end
			end
			temp2 = temp2 +1
		else
			temp3 = false
		end
	end
	
	temp = pos
	temp2 = 1
	temp3 = true
	
	while temp3 and temp2 <= jumpheight do
		temp = vector.add(temp, vector.new(0,1,0))
		if mypcall(passable, temp) then
			minpos = vector.add(temp, vector.new(0,0,mobsize[2].z))
			
			maxpos = vector.new(math.max(temp.x, minpos.x), math.max(temp.y, minpos.y), math.max(temp.z, minpos.z))
			minpos = vector.new(math.min(temp.x, minpos.x), math.min(temp.y, minpos.y), math.min(temp.z, minpos.z))
			
			minpos = vector.add(minpos, mobsize[1])
			maxpos = vector.add(maxpos, mobsize[2])
			
			if #minetest.find_nodes_in_area(minpos, maxpos, "group:solid") == 0 then
				maxpos = vector.subtract(maxpos, mobsize[2])
				if mypcall(standable, maxpos) then
					temp3 = false
					table.insert(result, id(maxpos))
				end
			end
			temp2 = temp2 +1
		else
			temp3 = false
		end
	end
	
	
	--falling
	temp = pos
	temp2 = 1
	
	temp = vector.add(temp, vector.new(mobsize[1].x,0,0))
	if mypcall(passable, temp) then
		while temp2 <= fallheight do
			temp = vector.add(temp, vector.new(0,-1,0))
			if mypcall(id, temp) and not mypcall(passable, temp) then
				break
			end
			if mypcall(standable, temp) then
				table.insert(result, id(temp))
				break
			end
			temp2 = temp2 +1
		end
	end
	
	temp = pos
	temp2 = 1
	
	temp = vector.add(temp, vector.new(mobsize[2].x,0,0))
	if mypcall(passable, temp) then
		while temp2 <= fallheight do
			temp = vector.add(temp, vector.new(0,-1,0))
			if mypcall(id, temp) and not mypcall(passable, temp) then
				break
			end
			if mypcall(standable, temp) then
				table.insert(result, id(temp))
				break
			end
			temp2 = temp2 +1
		end
	end
	
	temp = pos
	temp2 = 1
	
	temp = vector.add(temp, vector.new(0,0,mobsize[1].z))
	if mypcall(passable, temp) then
		while temp2 <= fallheight do
			temp = vector.add(temp, vector.new(0,-1,0))
			if mypcall(id, temp) and not mypcall(passable, temp) then
				break
			end
			if mypcall(standable, temp) then
				table.insert(result, id(temp))
				break
			end
			temp2 = temp2 +1
		end
	end
	
	temp = pos
	temp2 = 1
	
	temp = vector.add(temp, vector.new(0,0,mobsize[2].z))
	if mypcall(passable, temp) then
		while temp2 <= fallheight do
			temp = vector.add(temp, vector.new(0,-1,0))
			if mypcall(id, temp) and not mypcall(passable, temp) then
				break
			end
			if mypcall(standable, temp) then
				table.insert(result, id(temp))
				break
			end
			temp2 = temp2 +1
		end
	end
	
	
	
	return result
end
--===============================================


-- function that actually returns the desired result
local function scan()
	local result = {}
	local n = 0
	local na,nb = 0,0
	
	for id, pos in forxyz(basepos, size) do
		n = n+1
		if mypcall(passable, pos) then na = na +1 end
		if mypcall(standable, pos) then nb = nb +1 end
		if mypcall(passable, pos) and mypcall(standable, pos) then
			result[id] = {modifier = modifier[minetest.get_node(pos).name]}
			result[id].neighbours = neighbours(pos)
			result[id].neighbours = #result[id].neighbours > 0 and result[id].neighbours or nil
		end
	end
	
	minetest.chat_send_all("gescannte pos: " .. n)
	minetest.chat_send_all("passable pos: " .. na)
	minetest.chat_send_all("standable pos: " .. nb)	
	
	return result
end
--===============================================


-- functions used to save file
local function escape(txt)
	txt = string.gsub(txt, ":", "%%" .. string.byte(":"))
	return string.gsub(txt, "\"", "%%" .. string.byte("\""))
end

local empty_table = minetest.write_json({})

local function dataname()
	local vals = {}
	
	vals[1] = roomid
	vals[2] = mobsize[1].x == 0 and "" or mobsize[1].x
	vals[3] = mobsize[1].y == 0 and "" or mobsize[1].y
	vals[4] = mobsize[1].z == 0 and "" or mobsize[1].z
	vals[5] = mobsize[2].x == 0 and "" or mobsize[2].x
	vals[6] = mobsize[2].y == 0 and "" or mobsize[2].y
	vals[7] = mobsize[2].z == 0 and "" or mobsize[2].z
	vals[8] = jumpheight == 1 and "" or jumpheight
	vals[9] = fallheight == 1 and "" or fallheight
	vals[10] = size.x
	vals[11] = size.y
	vals[12] = size.z
	
	local temp = minetest.write_json(modifier)
	temp = temp == empty_table and "" or escape(string.sub(temp,1,-2))
	vals[13] = temp
	
	local temp = minetest.write_json(redefs)
	temp = temp == empty_table and "" or escape(string.sub(temp,1,-2))
	vals[14] = temp
	
	vals[15] = handlertype
	
	return table.concat(vals, "_") .. ".mtd"
end

local function save_file(path, name, data)
	data = minetest.write_json(data)
	data = minetest.compress(data, "deflate")
	data = minetest.compress(data, "deflate")
	
	local file, terror = io.open(path .. DIR_DELIM .. name, "wb")
	assert(file, "problem while creating file:" .. (terror or "error problem"))
	
	file:write(data)
	file:close()
end
--===============================================

minetest.register_chatcommand("scan", {
	func = function()
		save_file(minetest.get_worldpath(), dataname(), scan())
		minetest.chat_send_all("\27(c@#0ff)" .. dataname() .. "\27(c@#fff) saved")
	end
})