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

local function teleport(self, ply, destination)
	if ply:InVehicle() then ply:ExitVehicle() end
	
	ply:SetPos(destination)
	self:NetStreamModelGet("teleport", ply)()
end

--pyrition functions
function PYRITION:PlayerTeleport(ply, destination, teleport_type, note)
	local history = teleport_history[ply]
	
	if history then if table.insert(history, create_history_entry(ply, teleport_type, note)) > teleport_history_length then table.remove(history, 1) end
	else teleport_history[ply] = {create_history_entry(ply, teleport_type, note)} end
	
	teleport(self, ply, destination)
end

function PYRITION:PlayerTeleportReturn(ply, entry)
	local history = teleport_history[ply]
	
	if history and next(history) then
		local count = #history
		local entry = entry or count
		local poll = history[entry]
		
		if poll then
			for index = count, entry, -1 do table.remove(history, index) end
			
			teleport(self, ply, poll.Position)
			
			return true
		end
		
		return false, "pyrition.player.teleport.no_entry"
	end
	
	return false, "pyrition.player.teleport.no_history"
end

--hooks
hook.Add("PlayerDisconnected", "PyritionPlayerTeleport", function(ply) teleport_history[ply] = nil end)

--post
PYRITION:NetAddEnumeratedString("teleport_type", "bring", "goto", "send")