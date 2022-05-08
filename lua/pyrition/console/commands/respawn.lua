local COMMAND = {}

--command functions
function COMMAND:Execute(ply, targetting)
	local targets, message = targetting and PYRITION:PlayerFind(targetting, supplicant) or {ply}
	
	if targets then
		for index, target in ipairs(targets) do target:Spawn() end
		
		return true, "[:player] respawned [:targets]."
	end
	
	return false, message or "No valid targets."
end

--post
PYRITION:ConsoleCommandRegister("respawn", COMMAND)