--globals
PYRITION.PlayerTimeTotals = PYRITION.PlayerTimeTotals or {}

--pyrition functions
function PYRITION:PlayerTimeGetFirst(ply)
	local player_data = player_storage_players[ply]
	
	if player_data then return player_data.Time.first * 86400 end
end

function PYRITION:PlayerTimeGetTotal(ply)
	local player_data = player_storage_players[ply]
	
	if player_data then
		local time_data = player_data.Time
		
		return time_data.total + ply:TimeConnected() - time_data.LastSessionTime
	end
end

function PYRITION:PlayerTimeGetSession(ply)
	--todo: make sessions persist between maps
	--also use these sessions for the time storage's record column
	return ply:TimeConnected()
end
