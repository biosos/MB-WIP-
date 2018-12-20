texturetest={}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


local creator = minetest.get_dir_list(modpath..DIR_DELIM.."textures", false)



for i,v in ipairs(creator) do
	v = string.sub(v,1,-5)
	minetest.register_craftitem("texturetest:"..v, {
		description=""..v,
		inventory_image=v..".png",
	})
end