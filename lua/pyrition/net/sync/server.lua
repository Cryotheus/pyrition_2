util.AddNetworkString("pyrition_sync")

--locals
local drint = PYRITION._drint
local drint_level = 2
local maximum_sync_bits = 500000 --65533 bytes, minus the header bytes
local model_indices = PYRITION.NetSyncModelIndices or {}
local player_rebuilds = {}
local player_syncs = {}
local sync_models = PYRITION.NetSyncModels

--globals
PYRITION.NetSyncModelIndices = model_indices
PYRITION.NetSyncPlayers = player_syncs

--pyrition functions
function PYRITION:NetSyncAdd(class, ply)
	local index = model_indices[class] or 1
	local model = self:NetSyncModelCreate(class, ply)
	local syncs = player_syncs[ply]
	
	model.Identifier = index
	
	model_indices[class] = index + 1
	player_rebuilds[ply] = true
	
	if syncs then table.insert(syncs, model)
	else player_syncs[ply] = {model} end
	
	return model
end

function PYRITION:NetSyncBuildOrder(models) --returns an ordered list of sync models by priorities
	local priority_order = {}
	local priority_report = {}
	local model_order = {}
	
	for class, model in pairs(models) do
		local priority = model.Priority
		local report = priority_report[priority]
		
		if report then table.insert(report, model)
		else
			priority_report[priority] = {model}
			
			table.insert(priority_order, priority)
		end
	end
	
	table.sort(priority_order, function(alpha, bravo) return alpha > bravo end)
	
	for index, priority in ipairs(priority_order) do for sub_index, model in ipairs(priority_report[priority]) do table.insert(model_order, model) end end
	
	return model_order, priority_order, priority_report
end

function PYRITION:NetSyncGetModels(class, ply)
	local syncs = player_syncs[ply]
	
	if syncs then
		local matching_models = {}
		
		for index, model in ipairs(syncs) do if model.Class == class then table.insert(matching_models, model) end end
		
		return not table.IsEmpty(matching_models) and matching_models or false
	end
end

--hooks
hook.Add("Think", "PyritionNetSync", function()
	local completed_players
	local pyrition = PYRITION
	
	for ply, models in pairs(player_syncs) do
		local completed = {}
		local passed_model = false
		
		if player_rebuilds[ply] then
			models = pyrition:NetSyncBuildOrder(models)
			player_rebuilds[ply] = nil
			player_syncs[ply] = models
		end
		
		net.Start("pyrition_sync")
		
		for index, model in ipairs(pyrition:NetSyncBuildOrder(models)) do
			local class = model.Class
			local success, message
			model.MaximumBits = maximum_sync_bits
			
			if passed_model then net.WriteBool(true)
			else passed_model = true end
			
			if model.EnumerateClass then
				drint(drint_level, "enumerating", model)
				
				net.WriteBool(true)
				pyrition:NetWriteEnumeratedString("sync_model", class, ply)
			else
				drint(drint_level, "sending raw", model)
				
				net.WriteBool(false)
				net.WriteString(class)
			end
			
			net.WriteUInt(model.Identifier, 32)
			
			while model:CanWrite() and success == nil do success, message = model(ply) end
			
			if success == true then
				model:FinishWrite()
				net.WriteBool(true)
				
				drint(1, "completed " .. class)
				table.insert(completed, index)
			elseif success == nil then --ran out of space to write
				drint(drint_level, "stopped excessive writing")
				net.WriteBool(false)
				
				break
			else --erred
				net.WriteBool(false)
				
				if message then ErrorNoHaltWithStack(model .. " returned a " .. type(success) .. " value. Message: " .. message)
				else ErrorNoHaltWithStack(model .. " returned a " .. type(success) .. " value") end
				
				break
			end
		end
		
		local bits_written = select(2, net.BytesWritten())
		local stop_bits = math.ceil(bits_written / 8) * 8 - bits_written
		
		drint(drint_level, "sending " .. bits_written .. " bits to " .. tostring(ply) .. " (" .. stop_bits .. " stop bit modulo)")
		
		net.WriteUInt(0, stop_bits == 0 and 8 or stop_bits)
		net.Send(ply)
		
		for index, model_index in ipairs(table.Reverse(completed)) do table.remove(models, model_index) end
		
		if table.IsEmpty(models) then
			if completed_players then table.insert(completed_players, ply)
			else completed_players = {ply} end
		end
	end
	
	if completed_players then for index, ply in ipairs(completed_players) do player_syncs[ply] = nil end end
end)

--net
--net.Receive("pyrition_sync", function(length, ply) end)

PYRITION:NetAddEnumeratedString("sync_model")