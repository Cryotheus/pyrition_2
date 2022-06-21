local COMMAND = {
	Arguments = {
		{
			Class = "Player",
			Default = true
		}
	},
	
	Console = true
}

local player_meta = FindMetaTable("Player")

--custom fields
COMMAND.KillFunction = player_meta.Kill

--command function
function COMMAND:Execute(_ply, targets)
	local kill_function = self.KillFunction
	local slain = {IsPlayerList = true}
	
	for index, target in ipairs(targets) do
		if target:Alive() then
			kill_function(target)
			table.insert(slain, target)
		end
	end
	
	if #slain == 0 then return false, "pyrition.commands.slay.missed" end
	
	return true, "pyrition.commands.slay.success", {targets = slain}
end

--post
local COMMAND_SILENT = table.Copy(COMMAND)

COMMAND_SILENT.KillFunction = player_meta.KillSilent

--registration
PYRITION:ConsoleCommandRegister("slay", COMMAND)
PYRITION:ConsoleCommandRegister("slay silent", COMMAND_SILENT) --KillSilent doesn't seem to work right...