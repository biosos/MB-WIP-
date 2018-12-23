--Maphandler

-- for ground mobs
local function MaphandlerGroundV1(path)
	local self = {}
	local data
	
	local file = io.open(path, "rb")
	local txt = file:read("*a")
	file:close()
	file = nil
	
	txt = minetest.decompress(txt, "deflate")
	txt = minetest.decompress(txt, "deflate")
	data = minetest.parse_json(txt)
	txt = nil
	
	local size
	do
		local x,y,z = string.match(path, ".*" .. DIR_DELIM .. string.rep(".*_", 9) .. "(.*)_(.*)_(.*)_.*$")
		x,y,z = tonumber(x), tonumber(y), tonumber(z)
		size = vector.new(x,y,z)
	end
	
	function self:id(pos)
		local id = pos.x + (pos.y * size.x) + (pos.z * (size.x * size.y))
		
		return id
	end
	
	local function pos(id)
		local pos = {}
		
		pos.x = id % size.x
		pos.y = math.floor((id % (size.x * size.y)) / size.x)
		pos.z = math.floor(id / (size.x * size.y))
		
		return pos
	end
	
	function self:get_neighbours(id)
		local tbl =  data[id]["neighbours"]
				
		for k,v in pairs(tbl) do
			tbl[k] = self:get_node(v)
		end
	end
	
	function self:get_node(id)
		return {id = id, modifier = data[id][modifier], pos = pos(id)}
	end
	
	return self
end

astar.handlers.MaphandlerGroundV1 = MaphandlerGroundV1