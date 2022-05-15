--locals
local teleport_history = PYRITION.PlayerTeleportHistory
local teleport_history_length = PYRITION.PlayerTeleportHistoryLength

--local functions
local function create_history_entry(ply, teleport_type, note)
	return {
		Note = note or "pyrition.player.teleport.note",
		Position = ply:GetPos(),
		Type = teleport_type,
		Unix = os.time(),
	}
end

--pyrition functions
function PYRITION:PlayerTeleport(ply, destination, teleport_type, note)
	local history = teleport_history[ply]
	
	print("perform teleport", ply, destination, teleport_type, note)
	
	if history then if table.insert(history, create_history_entry(ply, teleport_type, note)) > teleport_history_length then table.remove(history, 1) end
	else teleport_history[ply] = {create_history_entry(ply, teleport_type, note)} end
	
	if ply:InVehicle() then ply:ExitVehicle() end
	
	ply:SetPos(destination)
	self:NetSyncAdd("teleport", ply)
end

function PYRITION:PlayerTeleportReturn(ply, entry)
	local history = teleport_history[ply]
	
	if history and next(history) then
		local count = #history
		local entry = entry or count
		local poll = history[entry]
		
		if poll then
			for index = count, entry, -1 do table.remove(history, index) end
			
			if ply:InVehicle() then ply:ExitVehicle() end
			
			ply:SetPos(poll.Position)
			self:NetSyncAdd("teleport", ply)
			
			return true
		end
		
		return false, "pyrition.player.teleport.no_entry"
	end
	
	return false, "pyrition.player.teleport.no_history"
end

--hooks
hook.Add("PlayerDisconnected", "PyritionPlayerTeleport", function(ply) teleport_history[ply] = nil end)