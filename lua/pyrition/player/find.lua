local prefix_functions = {
	["@"] = function(needle, supplicant) --player you're looking at
		--TODO: this!
		return false, "Unavailable."
	end,
	
	["#"] = function(...) return PYRITION:PlayerFindByUserID(...) end, --user id
	["$"] = function(...) return PYRITION:PlayerFindBySteamID(...) end, --steam id
	["%"] = function(needle, supplicant) return false, "Unavailable." end, --everyone in your user group and above
	
	["^"] = function(needle, supplicant) --yourself, everyone in your user group, or everyone in a user group
		if #needle > 0 then
			--find players of the specified user group
			local first_character = string.Left(needle, 1)
			
			--if they typed ^^ we want to get everyone in their group
			if first_character == "^" then return IsValid(supplicant) and PYRITION:PlayerFindByUserGroup(supplicant:GetUserGroup(), supplicant) or false end
			
			return PYRITION:PlayerFindByUserGroup(needle, supplicant)
		else
			local ply = supplicant or LocalPlayer and LocalPlayer()
			
			return {IsValid(ply) and ply or nil}
		end
	end,
	
	--everyone
	["*"] = function(needle, supplicant) return player.GetAll() end
}

--globals
PYRITION.PlayerFindPrefixes = prefix_functions

--pyrition functions
function PYRITION:PlayerFindByUserGroup(user_group, supplicant)
	local players = {}
	
	for index, ply in ipairs(player.GetAll()) do if ply:IsUserGroup(user_group) then table.insert(players, ply) end end
	
	return players
end

function PYRITION:PlayerFindBySteamID(needle, supplicant)
	local all_players = player.GetAll()
	local players = false
	
	if string.StartWith(needle, "STEAM_0:") then --STEAM_0 ID
		--more?
		for index, ply in ipairs(all_players) do if ply:SteamID() == needle then return {ply} end end
	elseif tonumber(needle) then --steam ID 64
		--more?
		for index, ply in ipairs(all_players) do if ply:SteamID64() == needle then return {ply} end end
	else --special IDs
		local players = {}
		
		for index, ply in ipairs(all_players) do
			local steam_id = ply:SteamID()
			
			if string.sub(steam_id, 9) == needle or steam_id == needle then table.insert(players, ply) end
		end
	end
	
	return players
end

function PYRITION:PlayerFindByUserID(user_id, supplicant)
	user_id = tonumber(user_id)
	
	if user_id then
		local ply = Player(user_id)
		
		if IsValid(ply) then return {ply} end
	end
	
	return false
end

function PYRITION:PlayerFindWithFallback(needle, supplicant, fallback, single)
	if needle and needle ~= "" then return self:PlayerFind(needle, supplicant, single) end
	
	return single and fallback or {fallback}
end

--pyrition hooks
function PYRITION:PyritionPlayerFind(needle, supplicant, single)
	if not needle or needle == "" then return false, "pyrition.player.find.targetless" end
	
	local first_character = string.Left(needle, 1)
	local invert = false
	local players
	
	if first_character == "!" then
		first_character = string.sub(needle, 2, 2)
		invert = true
		needle = string.sub(needle, 3)
	else first_character = string.sub(needle, 1, 1) end
	
	local prefix_function = prefix_functions[first_character]
	
	if prefix_function then players = prefix_function(string.sub(needle, 2), supplicant)
	else --find by name
		local all_players = player.GetAll()
		local builder = {}
		local player_count = #all_players
		
		needle = string.lower(needle)
		
		for index, ply in ipairs(all_players) do
			local name = string.lower(ply:Name())
			
			if string.StartWith(name, needle) then table.insert(builder, 1, ply)
			elseif string.find(name, needle, 1, true) then table.insert(builder, ply) end
		end
		
		if next(builder) then players = builder end
	end
	
	if invert then
		if players and next(players) then
			local players_map = {}
			
			for index, ply in ipairs(players) do players_map[ply] = index end
			
			players = {}
			
			for index, ply in ipairs(player.GetAll()) do if not players_map[ply] then table.insert(players, ply) end end
		else players = player.GetAll() end
	end
	
	if single then
		if istable(players) then
			if #players > 1 then return false, "pyrition.player.find.oversized" end
			
			return players[1]
		else return false, "pyrition.player.find.invalid" end
	end
	
	if players and next(players) then
		players.IsPlayerList = true
		
		return players
	end
	
	return false, "pyrition.player.find.invalid"
end