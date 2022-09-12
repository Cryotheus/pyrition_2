--locals
local COMMAND = {
	Arguments = {
		{
			Class = "Player",
			Default = true
		}
	},
	
	Console = true
}

local COMMAND_MAP = {
	Arguments = {},
	Console = true
}

--command functions
function COMMAND:Execute(ply, targets)
	targets = targets or {ply}
	
	if #targets == 1 and targets[1] == ply then
		cleanup.CC_Cleanup(ply, nil, {})
		
		return true, false
	else for index, target in ipairs(targets) do cleanup.CC_Cleanup(target, nil, {}) end end
	
	return true, nil, {targets = targets}
end

function COMMAND_MAP:Execute(_ply)
	game.CleanUpMap()
	
	return true
end

--post
PYRITION:ConsoleCommandRegister("cleanup", COMMAND)
PYRITION:ConsoleCommandRegister("cleanup map", COMMAND_MAP)