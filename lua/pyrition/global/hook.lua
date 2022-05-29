--all functions starting with Pyrition in the PYRITION table have functions of the same name without the Pyrition prefix created
--this newly made function will hook.Call the original function with varargs
--this is done AFTER all of Pyrition loads
--  prefix your method in PYRITION pith Pyrition to make it auto-convert into a hook.Call of the non-prefixed name
--  use GlobalHookCreate if you need it immediately
--  use GlobalHookCreate's post parameter (#2) if you want a hook prefixed PyritionPost called after the Pyrition prefixed hook
--  use GlobalHookConvert to make a method auto-convert into a hook
--  use GlobalHookConvert just like GlobalHookCreate, but make it immediately take affect by using the immediate parameter

--local functions
local function create_hooked_functions(self, key, hook_key, post)
	if post == nil then post = self["_GlobalHookPost_" .. key]
	else self["_GlobalHookPost_" .. key] = post end
	
	if post then
		local post_key = "PyritionPost" .. key
		
		self[key] = function(self, ...)
			local returns = {hook.Call(hook_key, self, ...)}
			
			hook.Call(post_key, self, ...)
			
			return unpack(returns)
		end
	else self[key] = function(self, ...) return hook.Call(hook_key, self, ...) end end
end

--makes my life, and the lives of extension developers much easier
function PYRITION:GlobalHookConvert(key, post, immediate)
	local hook_key = "Pyrition" .. key
	self[hook_key] = self[hook_key] or self[key]
	
	if immediate then create_hooked_functions(self, key, hook_key, post) end
end

function PYRITION:GlobalHookCreate(key, post)
	--this creates a macro to hook.Call the key prefixed by Pyrition
	--although this is done automatically to all functions starting with Pyrition in the PYRITION table
	create_hooked_functions(self, key, "Pyrition" .. key, post)
end

function PYRITION:GlobalHookRefresh()
	local hook_roster = {}
	
	--editing PYRITION while using pairs on it cause some values to get skipped
	for key, value in pairs(self) do
		if isfunction(value) and string.StartWith(key, "Pyrition") then
			table.insert(hook_roster, key)
		end
	end
	
	for index, key in ipairs(hook_roster) do
		local short_key = string.sub(key, 9)
		
		if not self[short_key] then self[short_key] = function(self, ...) return hook.Call(key, self, ...) end end
	end
end