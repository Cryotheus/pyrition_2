--locals
local duplex_insert = PYRITION._DuplexInsert
--local duplex_sort = PYRITION._DuplexSort
local maps = PYRITION.MapList

--pyrition functions
function PYRITION:MapBuildList()
	table.Empty(maps)
	
	local map_files = file.Find("maps/*.bsp", "GAME")
	
	for index, map_file in ipairs(map_files) do duplex_insert(maps, string.sub(map_file, 1, -5)) end
	
	--duplex_sort(maps)
	PYRITION:NetAddEnumeratedString("map", maps)
	
	return maps
end

--post
PYRITION:NetAddEnumeratedString("map")