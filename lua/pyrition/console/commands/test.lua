local COMMAND = {
	Arguments = {
		Required = 2,
		
		"Integer",
		"Time",
		"Player"
	},
	
	Console = true
}

function COMMAND:Execute(ply, integer, time, targets)
	if istable(targets) then PrintTable(targets) end
	
	return true
end

--post
PYRITION:ConsoleCommandRegister("test", COMMAND)