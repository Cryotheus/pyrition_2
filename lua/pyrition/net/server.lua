util.AddNetworkString("pyrition")
util.AddNetworkString("pyrition_teach")

--locals
local bits = PYRITION._Bits
local duplex_insert = PYRITION._DuplexInsert
local hacking_players = {}
local loading_players = {} --dictionary[ply] = ply:TimeConnected false if message emulated
local load_time = 30
local net_enumeration_bits = PYRITION.NetEnumerationBits --dictionary[namespace] = bits
local net_enumeration_players = PYRITION.NetEnumerationPlayers or {} --dictionary[ply] = dictionary[namespace] = report[string]
local net_enumeration_updates = PYRITION.NetEnumerationUpdates or {}
local net_enumerations = PYRITION.NetEnumeratedStrings --dictionary[namespace] = duplex[string]
local teaching_queue = {}

--local functions
local function loaded_players()
	local players = {}
	
	for index, ply in ipairs(player.GetAll()) do if not loading_players[ply] then table.insert(players) end end
	
	return players
end

local function read_enumerated_string(namespace, ply, text, enumeration)
	local enumerations = net_enumerations[namespace]
	
	assert(enumerations, "ID10T-2/S: Attempt to read enumerated string using non-existent namespace '" .. tostring(namespace) .. "'")
	
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

local function recipient_iterable(object)
	if object == true then return player.GetAll()
	elseif IsEntity(object) then return {object}
	elseif type(recipients) == "CRecipientFilter" then return recipients:GetPlayers()
	elseif istable(object) then return object end

	return false
end

local function recipient_pairs(recipients)
	local players = recipient_iterable(recipients)
	
	assert(istable(players), "ID10T-14: Bad argument #1 to 'recipient_pairs' (true, table, Player, or CRecipientFilter expected, got " .. type(recipients) .. ")")
	
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
	
	assert(enumerations, "ID10T-3/S: Attempt to write enumerated string using non-existent namespace '" .. tostring(namespace) .. "'")
	
	local enumeration = enumerations[text]
	
	assert(enumeration, "ID10T-3.1: Attempt to write enumerated string using non-existent enumeration '" .. tostring(text) .. "'")
	
	return track_enumerations(namespace, enumeration, recipients), text, enumeration, net_enumeration_bits[namespace]
end

--globals
PYRITION.NetEnumerationPlayers = net_enumeration_players
PYRITION.NetEnumerationUpdates = net_enumeration_updates
PYRITION._GetLoadedPlayers = loaded_players
PYRITION._ReadEnumeratedString = read_enumerated_string
PYRITION._RecipientIterable = recipient_iterable --internal
PYRITION._RecipientPairs = recipient_pairs --internal
PYRITION._WriteEnumeratedString = write_enumerated_string

--pyrition functions
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
	for ply, time_spawned in pairs(loading_players) do
		if time_spawned and ply:TimeConnected() - time_spawned > load_time then
			self:LanguageDisplay("prodigal", "pyrition.net.load.late", {
				duration = math.Round(ply:TimeConnected() - time_spawned, 2),
				player = ply,
				time = load_time,
			})
			
			loading_players[ply] = false
			
			self:NetPlayerInitialized(ply, true)
		end
	end
	
	if next(net_enumeration_updates) then
		for index, ply in ipairs(player.GetAll()) do
			if not loading_players[ply] then --no need to sync people who have yet to load in
				local model = self:NetStreamModelCreate("enumeration_bits", ply)
				
				model.Bits = net_enumeration_updates
			end
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

--pyrition hooks
function PYRITION:PyritionNetPlayerInitialized(ply, _emulated) PYRITION:LanguageDisplay("player_loaded", "pyrition.net.load", {player = ply}) end

function PYRITION:PyritionNetAddEnumeratedString(namespace, ...)
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
	local new_bits = bits(#duplex)
	
	if new_bits < 1 then net_enumeration_bits[namespace] = 1
	else net_enumeration_bits[namespace] = new_bits end
	
	--update the enumeration bits for clients if it changed
	if last_bits ~= new_bits and player.GetCount() > 0 then net_enumeration_updates[namespace] = new_bits end
end

--hooks
hook.Add("PlayerDisconnected", "PyritionNet", function(ply)
	loading_players[ply] = nil
	
	for namespace, tracker in pairs(net_enumeration_players) do tracker[ply] = nil end
end)

hook.Add("PlayerInitialSpawn", "PyritionNet", function(ply)
	loading_players[ply] = ply:TimeConnected()
	
	if ply:IsBot() then timer.Simple(math.min(1, load_time - 0.1), function() PYRITION:NetPlayerInitialized(ply) end) end
end)

--net
net.Receive("pyrition", function(_length, ply)
	if loading_players[ply] == nil and false then --RELEASE: remove "and false" once done debugging
		if sv_allowcslua:GetBool() then return end
		
		if hacking_players[ply] then ply:Kick("#HLX_KILL_ENEMIES_WITHMANHACK_NAME")
		else
			PYRITION:LanguageDisplay("hacker", "pyrition.net.load.hacker", {player = ply})
			
			hacking_players[ply] = true
		end
	else
		if loading_players[ply] == false then
			PYRITION:LanguageDisplay("prodigal", "pyrition.net.load.delayed", {player = ply})
			PYRITION:NetPlayerInitialized(ply, true)
		else PYRITION:NetPlayerInitialized(ply, false) end
		
		loading_players[ply] = nil
	end
end)

--post
PYRITION:GlobalHookCreate("NetAddEnumeratedString")