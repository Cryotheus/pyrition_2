--locals
local duplex_insert = PYRITION._DuplexInsert
local map_delay = 60 --TODO: ConVar this!
local map_vote_percentage = 0.5 --TODO: ConVar this!
local map_vote_threshold = 3 --TODO: ConVar this!
local map_votes = PYRITION.MapVotes or {}
local maps = PYRITION.MapList
local player_votes = PYRITION.MapPlayerVotes or {}

--globals
PYRITION.MapPlayerVotes = player_votes
PYRITION.MapVotes = map_votes

--pyrition functions
function PYRITION:MapBuildList()
	table.Empty(maps)
	
	local map_files = file.Find("maps/*.bsp", "GAME")
	
	for index, map_file in ipairs(map_files) do duplex_insert(maps, string.StripExtension(map_file)) end
	
	--duplex_sort(maps)
	PYRITION:NetAddEnumeratedString("map", maps)
	
	return maps
end

function PYRITION:MapChange(map_name)
	self.MapChanges = RealTime() + map_delay
	self.MapChanging = true
	self.MapChangesTo = map_name
	
	table.Empty(map_votes)
	table.Empty(player_votes)
	
	self:LanguageQueue(true, "pyrition.map.change", {
		map = map_name,
		time = map_delay
	})
end

function PYRITION:MapVote(ply, map_name)
	if self.MapChanging then return false, "pyrition.map.fail.change" end
	
	local current_vote = player_votes[ply]
	
	if current_vote then
		if current_vote == map_name then return false, "pyrition.map.fail.duplicate" end
		
		PYRITION:MapVoteAnnul(ply)
	end
	
	local current_votes = map_votes[map_name] or 0
	local new_votes = current_votes + 1
	
	map_votes[map_name] = new_votes
	player_votes[ply] = map_name
	
	if new_votes > map_vote_threshold and new_votes / player.GetCount() > map_vote_percentage then self:MapChange(map_name) end
	
	return true
end

function PYRITION:MapVoteAnnul(map_name)
	--remove all votes on a map
	if map_name then
		local victims = {IsPlayerList = true}
		
		for ply, map_voted in pairs(player_votes) do if map_voted == map_name then table.insert(victims, ply) end end
		for index, ply in ipairs(victims) do player_votes[ply] = nil end
		
		map_votes[map_name] = 0
		
		return next(victims) and victims or false
	end
	
	return false
end

function PYRITION:MapVoteRetract(ply)
	--remove a player's vote
	local map_name = player_votes[ply]
	
	if map_name then
		map_votes[map_name] = map_votes[map_name] - 1
		player_votes[ply] = nil
		
		return true
	end
	
	return false
end
--post
PYRITION:MapBuildList()
PYRITION:NetAddEnumeratedString("map")