--all functions starting with Pyrition in the PYRITION table have functions of the same name without the Pyrition prefix created
--this newly made function will hook.Call the original function with varargs
--this is done AFTER all of Pyrition loads
--if you need it earlier do PYRITION:GlobalHookCreate("ExampleKey") do not prefix whats in here with Pyrition
--remember that on global/shared.lua reload, we clear all functions in the PYRITION table

--makes my life easier
function PYRITION:GlobalHookCreate(key)
	--this creates a macro to hook.Call the key prefixed by Pyrition
	--although this is done automatically to all functions starting with Pyrition in the PYRITION table
	local hook_key = "Pyrition" .. key
	
	self[key] = function(self, ...) return hook.Call(hook_key, self, ...) end
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