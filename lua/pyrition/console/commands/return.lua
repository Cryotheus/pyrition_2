local COMMAND = {
	Arguments = {
		{
			Class = "Player",
			Default = true
		}
	},
	
	Console = true,
	Required = 1
}

local COMMAND_TO = {
	Arguments = {
		Required = 2,
		
		{
			Class = "Player",
			Default = true
		},
		
		{
			Class = "Integer",
			Maximum = PYRITION.PlayerTeleportHistoryLength,
			Minimum = 1
		}
	},
	
	Console = true
}

--command function
function COMMAND:Execute(_ply, targets)
	local returners = {IsPlayerList = true}
	
	for index, target in ipairs(targets) do PYRITION:PlayerTeleportReturn(target) end
	
	if #returners == 0 then return false, "pyrition.commands.return.missed" end
	
	return true, "pyrition.commands.return.success", {returners = returners}
end

function COMMAND_TO:Execute(_ply, targets, entry)
	local returners = {IsPlayerList = true}
	
	for index, target in ipairs(targets) do if PYRITION:PlayerTeleportReturn(target, entry) then table.insert(returners, target) end end
	
	if #returners == 0 then return false, "pyrition.commands.return.missed" end
	
	return true, "pyrition.commands.return.success", {targets = returners}
end

--post
PYRITION:ConsoleCommandRegister("return", COMMAND)
PYRITION:ConsoleCommandRegister("return using", COMMAND_TO)