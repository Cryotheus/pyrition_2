local maps = PYRITION.MapList or {}

--globals
PYRITION.MapList = maps

--local functions
local function defix(map)
	local _, finish = string.find(map, "_", 1, true)
	
	if not finish or finish > 6 then return false end
	
	return string.sub(map, finish + 1)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Map", function(settings, ply, argument)
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
end, function(settings, executor, argument)
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
end)