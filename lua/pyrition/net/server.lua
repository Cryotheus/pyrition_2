util.AddNetworkString("pyrition")
util.AddNetworkString("pyrition_teach")

local bits = PYRITION._Bits
local duplex_insert = duplex.Insert
local duplex_remove = duplex.Remove
local load_time = 30
local net_enumeration_bits = PYRITION.NetEnumerationBits --dictionary[namespace] = bits
local net_enumeration_players = PYRITION.NetEnumerationPlayers or {} --dictionary[ply] = dictionary[namespace] = report[string]
local net_enumeration_updates = PYRITION.NetEnumerationUpdates or {}
local net_enumerations = PYRITION.NetEnumeratedStrings --dictionary[namespace] = duplex[string]
local recipient_iterable = PYRITION._RecipientIterable
local sv_allowcslua = GetConVar("sv_allowcslua")
local teaching_queue = {}

local function read_enumerated_string(namespace, ply, text, enumeration)
	local enumerations = net_enumerations[namespace]

	assert(enumerations, "Attempt to read enumerated string using non-existent namespace '" .. tostring(namespace) .. "'")

	if text then
		--we're not king tut, we return if there's text and it's not restricted if ply is provided
		if ply then
			--we must verify the enumeration, don't trust the client!
			local enumeration = enumerations[text]

			if enumeration then
				local teaching = teaching_queue[ply]

				if teaching then
					local namespace_teaching = teaching[namespace]

					if namespace_teaching then namespace_teaching[enumeration] = true
					else teaching[namespace] = {[enumeration] = true} end
				else teaching_queue[ply] = {[namespace] = {[enumeration] = true}} end
			end
		end

		return text
	end

	return enumerations[enumeration]
end


local function recipient_pairs(recipients)
	local players = recipient_iterable(recipients)

	assert(istable(players), "Bad argument #1 to 'recipient_pairs' (true, table, Player, or CRecipientFilter expected, got " .. type(recipients) .. ")")

	return ipairs(players), players, 0
end

local function track_enumerations(namespace, enumeration, recipients)
	if true then return true end

	local send_raw = false
	local tracker = net_enumeration_players[namespace]

	for index, ply in recipient_pairs(recipients) do
		local player_tracker = tracker[ply]

		if player_tracker then
			if not player_tracker[enumeration] then
				send_raw = true
				player_tracker[enumeration] = true
			end
		else
			send_raw = true
			tracker[ply] = {[enumeration] = true}
		end
	end

	return send_raw
end

local function write_enumerated_string(namespace, text, recipients)
	local enumerations = net_enumerations[namespace]

	assert(enumerations, "Attempt to write enumerated string using non-existent namespace '" .. tostring(namespace) .. "'")

	local enumeration = enumerations[text]

	assert(enumeration, "Attempt to write enumerated string using non-existent enumeration '" .. tostring(text) .. "'")

	return track_enumerations(namespace, enumeration, recipients), text, enumeration, net_enumeration_bits[namespace]
end

PYRITION.NetHackingPlayers = PYRITION.NetHackingPlayers or {}
PYRITION.NetLoadedPlayers = PYRITION.NetLoadedPlayers or {} --duplex of players
PYRITION.NetLoadingPlayers = PYRITION.NetLoadingPlayers or {} --dictionary[ply] = ply:TimeConnected false if message emulated
PYRITION.NetEnumerationPlayers = net_enumeration_players
PYRITION.NetEnumerationUpdates = net_enumeration_updates
PYRITION._ReadEnumeratedString = read_enumerated_string
PYRITION._RecipientPairs = recipient_pairs --internal
PYRITION._WriteEnumeratedString = write_enumerated_string

function PYRITION:NetIsEnumerated(namespace, index)
	local enumerations = net_enumerations[namespace]

	if enumerations then return enumerations[index] or false end
end

function PYRITION:NetReadEnumeratedString(namespace, ply)
	return read_enumerated_string(
		namespace,
		ply,
		net.ReadBool() and net.ReadString(),
		net.ReadUInt(net_enumeration_bits[namespace]) + 1
	)
end

function PYRITION:NetThinkServer()
	local loading_players = self.NetLoadingPlayers

	for ply, time_spawned in pairs(loading_players) do
		if time_spawned and ply:TimeConnected() - time_spawned > load_time then
			self:LanguageDisplay("prodigal", "pyrition.net.load.late", {
				duration = math.Round(ply:TimeConnected() - time_spawned, 2),
				player = ply,
				time = load_time,
			})

			loading_players[ply] = false

			duplex_insert(self.NetLoadedPlayers, ply)
			self:NetPlayerInitialized(ply, true)
		end
	end

	if next(net_enumeration_updates) then
		for index, ply in ipairs(self.NetLoadedPlayers) do
			--TODO: try using PYRITION:NetStreamModelQueue
			local model = self:NetStreamModelCreate("EnumerationBits", ply)

			model.Bits = net_enumeration_updates
		end

		table.Empty(net_enumeration_updates)
	end

	if next(teaching_queue) then
		for ply, namespaces in pairs(teaching_queue) do
			net.Start("pyrition_teach")

			local passed_namespace = false

			for namespace, teach_enumerations in pairs(namespaces) do
				local bits = net_enumeration_bits[namespace]
				local enumerations = net_enumerations[namespace]
				local passed_enumeration = false

				net.WriteString(namespace)

				for enumeration in pairs(teach_enumerations) do
					net.WriteString(enumerations[enumeration])
					net.WriteUInt(enumeration - 1, bits)

					if passed_enumeration then net.WriteBool(true)
					else passed_enumeration = true end
				end

				net.WriteBool(false)

				if passed_namespace then net.WriteBool(true)
				else passed_namespace = true end
			end

			net.WriteBool(false)
			net.Send(ply)
		end

		table.Empty(teaching_queue)
	end
end

function PYRITION:NetWriteEnumeratedString(namespace, text, recipients)
	local send_raw, text, enumeration, enumeration_bits = write_enumerated_string(namespace, text, recipients)

	if send_raw then
		net.WriteBool(true)
		net.WriteString(text)
	else net.WriteBool(false) end

	net.WriteUInt(enumeration -1, enumeration_bits)
end

function PYRITION:HOOK_NetAddEnumeratedString(namespace, ...)
	local duplex = net_enumerations[namespace]
	local last_bits = 0
	local texts = {...}

	--create new duplex
	if not duplex then
		duplex = {}
		net_enumerations[namespace] = duplex
		net_enumeration_players[namespace] = {}
	end

	--add enumerations
	for index, text in ipairs(texts) do
		if istable(text) then --unpack table arguments
			--we don't want to modify the original table
			text = table.Copy(text)

			local first = table.remove(text, 1)
			local next_index = index + 1

			--texts[index] = first --muda!

			for sub_index, sub_text in ipairs(text) do table.insert(texts, next_index, sub_text) end

			text = first
		end

		duplex_insert(duplex, text)
	end

	--update bits
	local new_bits = math.max(bits(#duplex), 1)
	net_enumeration_bits[namespace] = new_bits

	--update the enumeration bits for clients if it changed
	if last_bits ~= new_bits and player.GetCount() > 0 then net_enumeration_updates[namespace] = new_bits end
end

function PYRITION:HOOK_NetPlayerInitialized(ply, _emulated) PYRITION:LanguageDisplay("player_loaded", "pyrition.net.load", {player = ply}) end

hook.Add("PlayerDisconnected", "PyritionNet", function(ply)
	if ply == nil then return end

	PYRITION.NetHackingPlayers[ply] = nil
	PYRITION.NetLoadingPlayers[ply] = nil

	duplex_remove(PYRITION.NetLoadedPlayers, ply)

	for namespace, tracker in pairs(net_enumeration_players) do tracker[ply] = nil end
end)

hook.Add("PlayerInitialSpawn", "PyritionNet", function(ply)
	PYRITION.NetLoadingPlayers[ply] = ply:TimeConnected()

	if ply:IsBot() then
		timer.Simple(0.5, function()
			if not ply:IsValid() then return end

			duplex_insert(PYRITION.NetLoadedPlayers, ply)
			PYRITION:NetPlayerInitialized(ply)
		end)
	end
end)

net.Receive("pyrition", function(_length, ply)
	local loading_players = PYRITION.NetLoadingPlayers

	if loading_players[ply] == nil then
		if sv_allowcslua:GetBool() then
			PYRITION.NetHackingPlayers[ply] = nil

			return
		end

		if PYRITION.NetHackingPlayers[ply] then ply:Kick("#HLX_KILL_ENEMIES_WITHMANHACK_NAME")
		else
			PYRITION:LanguageDisplay("hacker", "pyrition.net.load.hacker", {player = ply})

			PYRITION.NetHackingPlayers[ply] = true
		end
	else
		if loading_players[ply] == false then
			PYRITION:LanguageDisplay("prodigal", "pyrition.net.load.delayed", {player = ply})
			PYRITION:NetPlayerInitialized(ply, true)
		else
			duplex_insert(PYRITION.NetLoadedPlayers, ply)
			PYRITION:NetPlayerInitialized(ply, false)
		end

		loading_players[ply] = nil
	end
end)

PYRITION:GlobalHookCreate("NetAddEnumeratedString")