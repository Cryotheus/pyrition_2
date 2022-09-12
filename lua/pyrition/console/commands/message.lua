--locals
local COMMAND = {
	Arguments = {
		Required = 2,
		
		{
			Class = "Player",
			Selfless = true
		},
		
		{
			Class = "String",
			Maximum = 2000
		}
	},
	
	Console = true,
	SilentResponse = true
}

--command functions
function COMMAND:Execute(ply, targets, message) return PYRITION:PlayerMessage(ply, targets, message) end

--post
PYRITION:ConsoleCommandRegister("message", COMMAND)