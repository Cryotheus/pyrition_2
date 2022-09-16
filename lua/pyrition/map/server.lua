util.AddNetworkString("pyrition_map")

--locals
local duplex_inherit_entry = PYRITION._DuplexInheritEntry
local duplex_insert = PYRITION._DuplexInsert
local map_vote_percentage = 0.5 --RELEASE: ConVar this!
local map_vote_threshold = 3 --RELEASE: ConVar this!
local map_votes = PYRITION.MapVotes
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

function PYRITION:MapCancel()
	self.MapChanges = nil
	self.MapChanging = false
	self.MapChangesTo = nil
	
	hook.Remove("Think", "PyritionMap")
	net.Start("pyrition_map")
	net.WriteBool(false)
	net.Broadcast()
end

function PYRITION:MapChange(map_name, delay)
	local delay = delay or 60
	local time = CurTime() + delay
	
	self.MapChanges = time
	self.MapChanging = true
	self.MapChangesTo = map_name
	
	hook.Add("Think", "PyritionMap", function() PYRITION:MapThink() end)
	table.Empty(map_votes)
	table.Empty(player_votes)
	
	if delay > 0 then
		net.Start("pyrition_map")
		net.WriteBool(true)
		net.WriteFloat(time)
		self:NetWriteEnumeratedString("map", map_name, true)
		net.Broadcast()
	end
	
	self:MapSync(map_name)
end

function PYRITION:MapDisable(map_name) end --coming soon!
function PYRITION:MapDisableGame(game_root) end --coming soon!
function PYRITION:MapEnable(map_name) end --coming soon!
function PYRITION:MapSync(map_name) duplex_inherit_entry(self:NetStreamModelQueue("map", true, {}), maps, map_name) end

function PYRITION:MapThink()
	if CurTime() < self.MapChanges then return end
	
	hook.Remove("Think", "PyritionMap")
	RunConsoleCommand("changelevel", self.MapChangesTo)
end

function PYRITION:MapVote(ply, map_name)
	if self.MapChanging then return false, "pyrition.map.fail.change" end
	if ply:IsBot() then return false end
	
	local current_vote = player_votes[ply]
	
	if current_vote then
		if current_vote == map_name then return false, "pyrition.map.fail.duplicate" end
		
		PYRITION:MapVoteRetract(ply)
	end
	
	local current_votes = map_votes[map_name] or 0
	local new_votes = current_votes + 1
	local player_count = #player.GetHumans()
	
	map_votes[map_name] = new_votes
	player_votes[ply] = map_name
	
	if (new_votes > map_vote_threshold or map_vote_threshold < player_count) and new_votes / player_count > map_vote_percentage then
		--we should probably wait until players from the previous map have all connected
		self:MapChange(map_name)
	end
	
	self:MapSync(map_name)
	
	return true
end

function PYRITION:MapVoteAnnul(map_name)
	--remove all votes on a map
	if map_name then
		local victims = {IsPlayerList = true}
		
		for ply, map_voted in pairs(player_votes) do if map_voted == map_name then table.insert(victims, ply) end end
		for index, ply in ipairs(victims) do player_votes[ply] = nil end
		
		map_votes[map_name] = 0
		
		self:MapSync(map_name)
		
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
		
		self:MapSync(map_name)
		
		return true
	end
	
	return false
end

--post
PYRITION:MapBuildList()
PYRITION:NetAddEnumeratedString("map")