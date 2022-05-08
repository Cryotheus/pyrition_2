local COMMAND = {}
local player_meta = FindMetaTable("Player")

--custom fields
COMMAND.KillFunction = player_meta.Kill

--command function
function COMMAND:Execute(ply, targetting)
	local targets, message = targetting and PYRITION:PlayerFind(targetting, supplicant) or {ply}
	
	if targets then
		local kill_function = self.KillFunction
		local slain = {}
		
		for index, target in ipairs(targets) do
			if target:Alive() then
				kill_function(target)
				table.insert(slain, target)
			end
		end
		
		if table.IsEmpty(slain) then return false, "No living targets to slay." end
		
		return true, "[:player] slayed [:targets]."
	end
	
	return false, message or "No valid targets."
end

--post
local COMMAND_SILENT = table.Copy(COMMAND)

COMMAND_SILENT.KillFunction = player_meta.KillSilent

--registration
PYRITION:ConsoleCommandRegister("slay", COMMAND)
PYRITION:ConsoleCommandRegister("slay silent", COMMAND_SILENT) --KillSilent doesn't seem to work right...