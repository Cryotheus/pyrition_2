local COMMAND = {
	Arguments = {"Player"},
	Console = true
}

local COMMAND_MAP = {
	Arguments = {},
	Console = true
}

--command functions
function COMMAND:Execute(_ply, targets)
	for index, target in ipairs(targets) do cleanup.CC_Cleanup(target) end
	
	return true, nil, {targets = targets}
end

function COMMAND_MAP:Execute(_ply)
	game.CleanUpMap()
	
	return true
end

--post
PYRITION:ConsoleCommandRegister("cleanup", COMMAND_MAP)
PYRITION:ConsoleCommandRegister("cleanup map", COMMAND_MAP)