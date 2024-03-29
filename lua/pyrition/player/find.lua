local prefix_functions = {
	["@"] = function(_needle, _supplicant) --player you're looking at
		--POST: this!
		return false, "Unavailable."
	end,

	["#"] = function(...) return PYRITION:PlayerFindByUserID(...) end, --user id
	["$"] = function(...) return PYRITION:PlayerFindBySteamID(...) end, --steam id
	["%"] = function(_needle, _supplicant) return false, "Unavailable." end, --everyone in your user group and above

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

	["*"] = function(_needle, _supplicant) return player.GetAll() end --everyone
}

PYRITION.PlayerFindPrefixes = prefix_functions

function PYRITION:PlayerFindByUserGroup(user_group, _supplicant)
	local players = {}

	for index, ply in ipairs(player.GetAll()) do if ply:IsUserGroup(user_group) then table.insert(players, ply) end end

	return players
end

function PYRITION:PlayerFindBySteamID(needle, _supplicant)
	local all_players = player.GetAll()
	local players = false

	if string.lower(needle) == "bot" then return player.GetBots() end --$BOT
	if string.StartWith(needle, "STEAM_0:") then for index, ply in ipairs(all_players) do if ply:SteamID() == needle then return {ply} end end --STEAM_0 ID
	elseif tonumber(needle) then for index, ply in ipairs(all_players) do if ply:SteamID64() == needle then return {ply} end end --steam ID 64
	else --STEAM_0 ID without STEAM_0:
		local players = {}

		for index, ply in ipairs(all_players) do
			local steam_id = ply:SteamID()

			if string.sub(steam_id, 9) == needle or steam_id == needle then table.insert(players, ply) end
		end
	end

	return players
end

function PYRITION:PlayerFindByUserID(user_id, _supplicant)
	user_id = tonumber(user_id)

	if user_id then
		local ply = Player(user_id)

		if IsValid(ply) then return {ply} end
	end

	return false
end

function PYRITION:PlayerFindWithFallback(needle, supplicant, fallback, single, exclude_supplicant)
	if needle and needle ~= "" then return self:PlayerFind(needle, supplicant, single, exclude_supplicant) end

	if fallback == game.GetWorld() then return nil end

	return single and fallback or {
		IsPlayerList = true,
		fallback
	}
end

function PYRITION:HOOK_PlayerFind(needle, supplicant, single, exclude_supplicant, allow_empty)
	if allow_empty then needle = needle or ""
	elseif not needle or needle == "" then return false, "pyrition.player.find.targetless" end

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

	if players then
		if exclude_supplicant then
			--remove the supplicant from the table
			for index, ply in ipairs(players) do if ply == supplicant then table.remove(players, index) end end
		end

		if next(players) then
			players.IsPlayerList = true

			return players
		end
	end

	return false, "pyrition.player.find.invalid"
end