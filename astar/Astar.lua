local function Astar()
	local self = {}

	local data = {}
	local activeHandlers = {}
	local handlerIndices = {}
	
	function self:register_data(name, path)
		if not string.match(path, "%.mtd$") then
			return
		end
		
		data[name] = path
	end
	
	function self:browse_data(path)
		local files = minetest.get_dir_list(path, false)
		
		for _,path in ipairs(files) do
			data[string.match(path, "(.+)%.mtd$")] = path
		end
		
		files = minetest.get_dir_list(path, true)
		
		for _,folder in ipairs(files) do
			self:browse_data(path .. DIR_DELIM .. folder)
		end
	end
	
	function self:request_handler(name)
		local handlertype = string.match(data, "_(.-)$")
		
		if not handlerIndices[handlertype] then
			local i = 1
			while activeHandlers[i] do
				i = i + 1
			end
			
			activeHandlers[i] = astar.handlers[handlertype](data[name])
			handlerIndices[handlertype] = i
			
			return activeHandlers[i], i
		else
			local handlerindex = handlerIndices[handlertype]
			
			return activeHandlers[handlerindex], handlerindex
		end
	end
	
	function self:remove_handler(name) -- can be either its index or corresponding data
		if tonumber(data) then
			activeHandlers[data] = nil
			
			for k,v in pairs(handlerIndices) do
				if v == data then
					handlerIndices[k] = nil
					break
				end
			end
		else
			local handlertype = string.match(name, "_(.-)$")
			local handlerindex = handlerIndices[handlertype]
			
			activeHandlers[handlerindex] = nil
			handlerIndices[handlertype] = nil
		end
	end
	
	function self:get_path(handler, basepos, startpos, targetpos, radius)
		if tonumber(handler) then
			handler = activeHandlers[handler]
		end
		
		radius = radius or 0
		
		startpos, targetpos = vector.subtract(startpos, basepos), vector.subtract(targetpos, basepos)
		startpos, targetpos = handler:id(startpos), handler:id(targetpos)
		
		local openList = astar.Heap(function(a,b)
			return (a.val.score == b.val.score) and (a.val.h <= b.val.h) or (a.val.score < b.val.score)
		end, {score = -math.huge, h = -math.huge})
		local closedList = {}
		
		local startnode, targetnode = handler:get_node(startpos), handler:get_node(targetpos)
		startnode.mcost = 0
		startnode.h = vector.distance(startnode.pos, endnode.pos)
		startnode.score = startnode.mcost + startnode.h
		
		do
			local startnodes = handler:get_neighbours(startpos)
			for _,node in ipairs(startnodes) do
				node.parent = startnode.id
				node.mcost = startnode.mcost + vector.distance(startnode.pos, node.pos)
				node.h = vector.distance(node.pos, targetnode.pos)
				node.score = node.mcost + node.h
				openList:insert(node, node.id)
			end
		end

		closedList[startnode.id] = startnode
		
		local flag
		while openList:get_first() do
			local first = openList:get_first()
			
			if first.h <= radius then
				flag = true
				break
			end
			
			local neighbours = handler:get_neighbours(first.id)
			
			openList:remove(1)
			closedList[first.id] = first
			
			for _,node in ipairs(neighbours) do
				node.parent = first.id
				node.mcost = first.mcost + vector.distance(first.pos, node.pos)
				node.h = vector.distance(node.pos, targetnode.pos)
				node.score = node.mcost + node.h
				openList:insert(node, node.id)
			end
		end
		
		local path
		if flag then
			tmppath = {}
			local first = openList:get_first()
			local i = 1
			
			tmppath[i] = first
			i = i + 1
			
			while first.parent do
				first = closedList[first.parent]
				tmppath[i] = first
				i = i + 1
			end
			
			path = {}
			for a,node in ipairs(tmppath) do
				path[a] = tmppath[i-a+1].pos
			end
		end
		
		return path
	end
end


setmetatable(astar,{__index = Astar()})
--astar.Astar = Astar()