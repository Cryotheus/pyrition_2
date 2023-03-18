--locals

--globals

--pyrition functions
function PYRITION:PyritionConsoleExecute(ply, arguments)
	if SERVER and ply:IsValid() then
		if ply:IsListenServerHost() then ply = game.GetWorld()
		else return false, "Only the server can run commands server side." end
	end
end