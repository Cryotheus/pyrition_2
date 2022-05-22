local COMMAND = {
	Arguments = {"Player"},
	Console = true
}

local COMMAND_TO = {
	Arguments = {
		Required = 2,
		
		{Class = "Player"},
		
		{
			Class = "Integer",
			Maximum = PYRITION.PlayerTeleportHistoryLength,
			Minimum = 1
		}
	},
	
	Console = true
}

--command function
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		local returners = {IsPlayerList = true}
		
		for index, target in ipairs(targets) do PYRITION:PlayerTeleportReturn(target) end
		
		if #returners == 0 then return false, "pyrition.commands.return.missed" end
		
		return true, "pyrition.commands.return.success", {returners = returners}
	end
	
	return false, message
end

function COMMAND_TO:Execute(ply, targetting, entry)
	local entry = tonumber(entry)
	local targets, message = PYRITION:PlayerFind(targetting, ply)
	
	if targets then
		local returners = {IsPlayerList = true}
		
		for index, target in ipairs(targets) do if PYRITION:PlayerTeleportReturn(target, entry) then table.insert(returners, target) end end
		
		if #returners == 0 then return false, "pyrition.commands.return.missed" end
		
		return true, "pyrition.commands.return.success", {targets = returners}
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("return", COMMAND)
PYRITION:ConsoleCommandRegister("return using", COMMAND_TO)