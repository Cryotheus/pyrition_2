local COMMAND = {
	Arguments = {"Player"},
	Console = true
}

--command functions
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		for index, target in ipairs(targets) do target:Spawn() end
		
		return true, "pyrition.commands.respawn.success", {targets = targets}
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("respawn", COMMAND)