--locals

--globals
PYRITION.ConsoleCommandRegistry = PYRITION.ConsoleCommandRegistry or {}

--pyrition functions
function PYRITION:PyritionConsoleCommandRegister(path, command_table)
	local registry = self.ConsoleCommandRegistry
	
	registry[path] = command_table
end