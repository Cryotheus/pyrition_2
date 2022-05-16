local COMMAND = {
	Arguments = {
		Required = 1,
		
		{Type = "String"}
	}
}

--command functions
function COMMAND:Execute(ply, map_name) RunConsoleCommand("changelevel", map_name) end

--post
PYRITION:ConsoleCommandRegister("map", COMMAND)