--locals
local COMMAND = {
	Arguments = {
		Required = 1,
		
		{
			Single = true,
			Class = "Player"
		},
		
		{
			Maximum = 448,
			Class = "String"
		}
	},
	
	Console = true
}

local COMMAND_MULTI = {
	Arguments = {
		Required = 1,
		
		{Class = "Player"},
		
		{
			Maximum = 448,
			Class = "String"
		}
	},
	
	Console = true
}

--command function
function COMMAND:Execute(_ply, target, reason)
	PYRITION:PlayerKick(target, reason)
	
	return true, reason and "pyrition.commands.kick.explicable" or "pyrition.commands.kick.inexplicable", {target = target, reason = reason}
end

function COMMAND_MULTI:Execute(_ply, targets, reason)
	for index, target in ipairs(targets) do PYRITION:PlayerKick(target, reason) end
	
	return true, reason and "pyrition.commands.kick.multiple.explicable" or "pyrition.commands.kick.multiple.inexplicable", {targets = targets, reason = reason}
end

--post
PYRITION:ConsoleCommandRegister("kick", COMMAND)
PYRITION:ConsoleCommandRegister("kick multiple", COMMAND_MULTI)