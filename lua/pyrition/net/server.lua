util.AddNetworkString("pyrition")
--util.AddNetworkString("pyrition_teach")

--locals
local color_significant = Color(255, 128, 64)
local drint = PYRITION._drint
local drint_level = 2
local loading_players = {} --dictionary[ply] = ply:TimeConnected false if message emulated
local load_time = 30
local net_enumeration_bits = PYRITION.NetEnumerationBits --dictionary[namespace] = bits
local net_enumeration_players = PYRITION.NetEnumerationPlayers or {} --dictionary[ply] = dictionary[namespace] = report[string]
local net_enumeration_updates = PYRITION.NetEnumerationUpdates or {}
local net_enumerations = PYRITION.NetEnumeratedStrings --dictionary[namespace] = duplex[string]
local teaching_queue

--local functions
local function bits(number) return number == 1 and 1 or math.ceil(math.log(number, 2)) end

local function recipient_pairs(recipients)
	if IsEntity(recipients) then recipients = {recipients}
	elseif type(recipients) == "CRecipientFilter" then recipients = recipients:GetPlayers() end
	
	assert(istable(recipients), "bad argument #1 to 'recipient_pairs' (table, Player, or CRecipientFilter expected, got " .. type(recipients) .. ")")
	
	return ipairs(recipients), recipients, 0
end

local function track_enumerations(namespace, enumeration, recipients)
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

--globals
PYRITION.NetEnumerationPlayers = net_enumeration_players
PYRITION.NetEnumerationUpdates = net_enumeration_updates
PYRITION._RecipientPairs = recipient_pairs --internal

--pyrition functions
function PYRITION:NetIsEnumerated(namespace, index)
	local enumerations = net_enumerations[namespace]
	
	if enumerations then return enumerations[index] or false end
end

function PYRITION:NetReadEnumeratedString(namespace, ply)
	local enumerations = net_enumerations[namespace]
	
	assert(enumerations, 'ID10T-2/S: Attempt to read enumerated string using non-existant namespace "' .. namespace .. '"')
	
	if net.ReadBool() then
		local text = net.ReadString()
		local enumeration = enumerations[text]
		
		if enumeration and ply then
			local teaching = teaching_queue[ply]
			
			if teaching then
				local namespace_teaching = teaching[namespace]
				
				if namespace_teaching then namespace_teaching[enumeration] = true
				else teaching[namespace] = {[enumeration] = true} end
			else teaching_queue[ply] = {[namespace] = {[enumeration] = true}} end
			
			--we should queue this up, yeah?
			--net.Start("pyrition")
			--net.WriteString(namespace)
			--net.WriteUInt(net_enumeration_bits[namespace], 5)
			--net.WriteBool(false)
			--net.Send(ply)
		end
		
		return text
	end
	
	return enumerations[net.ReadUInt(net_enumeration_bits[namespace])]
end

function PYRITION:NetWriteEnumeratedString(namespace, text, recipients)
	local enumerations = net_enumerations[namespace]
	
	assert(enumerations, 'ID10T-3/S: Attempt to write enumerated string using non-existant namespace "' .. namespace .. '"')
	
	local enumeration = enumerations[text]
	
	assert(enumeration, 'ID10T-3.1: Attempt to write enumerated string using non-existant enumeration "' .. text .. '"')
	
	local debug_net = DEBUG_PYRITION_NET
	local send_raw = track_enumerations(namespace, enumeration, recipients)
	
	if debug_net then
		DEBUG_PYRITION_NET = false
		
		drint(drint_level, "WriteEnum	" .. namespace .. "	" .. enumeration .. ":" .. text .. " (" .. net_enumeration_bits[namespace] .. ")\n")
	end
	
	net.WriteBool(send_raw)
	
	if send_raw then net.WriteString(text) end
	
	net.WriteUInt(enumeration - 1, net_enumeration_bits[namespace])
	
	if debug_net then DEBUG_PYRITION_NET = true end
end

--pyrition hooks
function PYRITION:PyritionNetPlayerInitialized(ply, emulated)
	MsgC(color_significant, "[Pyrition] ", color_white, ply:Name() .. (map_transition and " fully loaded into the server after the map change.\n" or " fully loaded into the server.\n"))
	
	for class, model_table in pairs(self.NetSyncModels) do
		--more?
		if model_table.InitialSync and model_table:InitialSync(ply, emulated) then self:NetSyncAdd(class, ply) end
	end
end

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
			local first = table.remove(text, 1)
			local next_index = index + 1
			
			--texts[index] = first --muda!
			
			for sub_index, sub_text in ipairs(text) do table.insert(texts, next_index, sub_text) end
			
			text = first
		end
		
		self:DuplexInsert(duplex, text)
	end
	
	--update bits
	local new_bits = bits(#duplex)
	
	net_enumeration_bits[namespace] = new_bits
	
	--update the enumeration bits for clients if it changed
	if last_bits ~= new_bits and player.GetCount() > 0 then net_enumeration_updates[namespace] = new_bits end
end

--hooks
hook.Add("PlayerDisconnected", "PyritionNet", function(ply)
	loading_players[ply] = nil
	
	for namespace, tracker in pairs(net_enumeration_players) do tracker[ply] = nil end
end)

hook.Add("PlayerInitialSpawn", "PyritionNet", function(ply) loading_players[ply] = ply:TimeConnected() end)

hook.Add("Think", "PyritionNet", function()
	for ply, time_spawned in pairs(loading_players) do
		if time_spawned and ply:TimeConnected() - time_spawned > load_time then
			MsgC(color_red, "A player (" .. tostring(ply) .. ") has exceeded " .. load_time .. " (took " .. ply:TimeConnected() - time_spawned .. ") seconds of spawn time and has yet to report initialization. Emulating a response.\n")
			
			loading_players[ply] = false
			
			PYRITION:NetPlayerInitialized(ply, true)
		end
	end
	
	if next(net_enumeration_updates) then
		local first = true
		local item_count
		local items
		
		for index, ply in ipairs(player.GetAll()) do
			if not loading_players[ply] then --no need to sync people who have yet to load in
				local model = PYRITION:NetSyncAdd("enumeration_bits", ply)
			
				if first then
					first = false
					items = model:BuildWriteList(net_enumeration_updates)
					item_count = #items
				else
					model.Items = items
					model.Maximum = item_count
				end
			end
		end
		
		table.Empty(net_enumeration_updates)
	end
	
	--[[
	if teaching_queue then
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
		
		teaching_queue = nil
	end --]]
	
	--else teaching_queue[ply] = {[namespace] = {[enumeration] = true}} end
	
	--we should queue this up, yeah?
	--net.Start("pyrition")
	--net.WriteString(namespace)
	--net.WriteUInt(net_enumeration_bits[namespace], 5)
	--net.WriteBool(false)
	--net.Send(ply)
end)

--net
net.Receive("pyrition", function(length, ply)
	if loading_players[ply] == nil and false then --TODO: remove "and false" once done debugging
		if sv_allowcslua:GetBool() then return end
		
		MsgC(color_red, "\n!!!\nA player (", ply, ") tried to send a load net message but has yet to be spawned! It is possible that they are hacking.\n!!!\n\n")
	else
		if loading_players[ply] == false then
			MsgC(
				color_red, "A player (" .. tostring(ply) .. ") had a belated load net message, an emulated one has been made.\n",
				color_white, "The above message is not an error, but a sign that clients are taking too long to load into your server.\n"
			)
		end
		
		loading_players[ply] = nil
		
		PYRITION:NetPlayerInitialized(ply, false)
	end
end)

--post
PYRITION:GlobalHookCreate("NetAddEnumeratedString")