--locals
local ARGUMENT = {}
local defix = PYRITION._DefixMap
local maps = PYRITION.MapList

--command argument methods
function ARGUMENT:Complete(_ply, _settings, argument)
	local completions = {}
	
	--add all maps prefixed with the text
	for index, map in ipairs(maps) do
		if string.StartWith(map, argument) then
			table.insert(completions, map)
		end
	end
	
	--add all maps prefixed with the text ignoring prefixes
	for index, map in ipairs(maps) do
		local defixed = defix(map)
		
		if defixed and string.StartWith(defixed, argument) then table.insert(completions, map) end
	end
	
	return completions
end

function ARGUMENT:Filter(_ply, _settings, argument)
	if not argument then return false end
	if maps[argument] then return true, argument end
	
	--if the map didn't have a direct reference, we need to search for it
	local found
	
	--if the argument is the map without a prefix, find that map
	--don't allow duplicates though
	for index, map in ipairs(maps) do
		local defixed = defix(map)
		
		if argument == defixed then
			if found then return false end
			
			found = map
		end
	end
	
	return true, found
end

--post
PYRITION:ConsoleCommandRegisterArgument("Map", ARGUMENT)