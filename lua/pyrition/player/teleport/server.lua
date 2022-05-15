--locals
local teleport_history = PYRITION.PlayerTeleportHistory
local teleport_history_length = PYRITION.PlayerTeleportHistoryLength

--pyrition functions
function PYRITION:PlayerTeleport(ply, destination)
	local history = teleport_history[ply]
	
	if history then if table.insert(history, ply:GetPos()) > teleport_history_length then table.remove(history, 1) end
	else teleport_history[ply] = {ply:GetPos()} end
	
	ply:SetPos(destination)
	self:NetSyncAdd("teleport", ply)
end

function PYRITION:PlayerTeleportReturn(ply, entry)
	local history = teleport_history[ply]
	
	if history and next(history) then
		local count = #history
		local entry = entry or count
		local position = history[entry]
		
		if position then
			for index = count, entry, -1 do table.remove(history, index) end
			
			ply:SetPos(position)
			self:NetSyncAdd("teleport", ply)
			
			return true
		end
		
		return false, "pyrition.player.teleport.no_entry"
	end
	
	return false, "pyrition.player.teleport.no_history"
end

--hooks
hook.Add("PlayerDisconnected", "PyritionPlayerTeleport", function(ply) teleport_history[ply] = nil end)