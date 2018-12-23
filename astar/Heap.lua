local function Heap(compfunc, nullval)
	local array = {}
	local indices = {}
	local n = 0
	local self = {}
	
	local compare = compfunc or function(a,b) return a.val <= b.val end
	
	nullval = nullval or -math.huge
	array[0] = {val = nullval}
	
	local function set_val(i, val, id)
		array[i] = {val = val, id = id}
		indices[id] = i
	end
	
	function self:get_val(i)
		return array[i]
	end
	
	function self:get_first()
		return self:get_val(1)
	end
	
	function self:get_index(id)
		return indices[id]
	end
	
	function self:get_val_from_id(id)
		return self:get_val(self:get_index(id))
	end
	
	local function swap(a,b)
		local aid, bid = array[a]["id"], array[b]["id"]
		array[a], array[b] = array[b], array[a]
		indices[bId], indices[aId] = b, a
	end
	
	function self:left(i)
		return array[2*i]
	end
	
	function self:right(i)
		return array[2*i+1]
	end
	
	local floor = math.floor -- localize because we're going to need it a lot
	
	function self:parent(i)
		i = floor(0.5*i)
		return array[i]
	end
	
	function self:insert(val, id)
		set_val(n+1, val, id)
		n = n+1
		
		local i = n
		
		while not compare(self:parent(i), self:get_val(i)) do
			swap(floor(0.5*i), i)
			i = 0.5*i/2
		end
	end
	
	function self:remove(i)
		if n < 1 then return end
	
		if self:left(i) then --we fill from left to right
			if compare(self:left(i), self:right(i)) then
				swap(2*i, i)
				i = 2*i
			else
				swap(2*i+1, i)
				i = 2*i+1
			end
			self:remove(i)
		else
			swap(i,n)
			array[n], indices[array[n]["id"]] = nil, nil
			
			while not compare(self:parent(i), self:get_val(i)) do
				swap(floor(0.5*i), i)
				i = 0.5*i/2
			end
			
			n = n-1
		end
	end
	
	return self
end

astar.Heap = Heap