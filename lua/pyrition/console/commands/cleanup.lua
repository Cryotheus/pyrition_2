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
PYRITION:ConsoleCommandRegister("cleanup database", COMMAND_MAP)
PYRITION:ConsoleCommandRegister("cleanup storage", COMMAND_MAP)
PYRITION:ConsoleCommandRegister("cleanup map", COMMAND_MAP)