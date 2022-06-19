--locals
local map_votes = PYRITION.MapVotes or {}
local maps = PYRITION.MapList or {}

--local functions
local function defix(map)
	local _, finish = string.find(map, "_", 1, true)
	
	if not finish or finish > 6 then return false end
	
	return string.sub(map, finish + 1)
end

--globals
PYRITION.MapList = maps
PYRITION.MapVotes = map_votes
PYRITION._DefixMap = defix