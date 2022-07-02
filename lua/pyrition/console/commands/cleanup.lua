local COMMAND_MAP = {
	Arguments = {},
	Console = true
}

--command functions
function COMMAND_MAP:Execute(_ply)
	game.CleanUpMap()
	
	return true
end

--post
PYRITION:ConsoleCommandRegister("cleanup map", COMMAND_MAP)