--command for debugging
local COMMAND = {
	Arguments = {
		Required = 3,
		
		"Integer",
		"Time",
		
		{
			Class = "Player",
			Optional = true
		},
		
		"String"
	},
	
	Console = true
}

function COMMAND:Execute(ply, integer, time, targets)
	print(ply, integer, time, targets)
	
	if istable(targets) then PrintTable(targets) end
	
	return true
end

--post
PYRITION:ConsoleCommandRegister("test", COMMAND)