local COMMAND = {}
local COMMAND_MULTI = {}

--command function
function COMMAND:Execute(ply, targetting, reason)
	local target, message = PYRITION:PlayerFind(targetting, ply, true)
	
	if target then
		target:Kick(reason or "")
		
		return true, (reason and "pyrition.commands.kick.explicable" or "pyrition.commands.kick.inexplicable"), {target = target:Name(), reason = reason}
	end
	
	return false, message
end

function COMMAND_MULTI:Execute(ply, targetting, reason)
	local targets, message = targetting and PYRITION:PlayerFind(targetting, supplicant)
	
	if targets then
		reason = reason or ""
		
		for index, target in ipairs(targets) do target:Kick(reason) end
		
		return true, (reason and "pyrition.commands.kick.multiple.explicable" or "pyrition.commands.kick.multiple.inexplicable"), {targets = targets, reason = reason}
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("kick", COMMAND)
PYRITION:ConsoleCommandRegister("kick multiple", COMMAND_MULTI)
