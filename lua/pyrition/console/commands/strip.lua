--locals
local COMMAND = {
	Arguments = {"Player"},
	Console = true
}

local player_meta = FindMetaTable("Player")

--custom fields
COMMAND.StripFunction = player_meta.StripWeapons

--command function
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		local strip_function = self.StripFunction
		local stripped = {IsPlayerList = true}
		
		for index, target in ipairs(targets) do
			if target:Alive() then
				strip_function(target)
				table.insert(stripped, target)
			end
		end
		
		if #stripped == 0 then return false, "pyrition.commands.strip.missed" end
		
		return true, "pyrition.commands.strip.success", {targets = stripped}
	end
	
	return false, message
end

--post
local COMMAND_ALL = table.Copy(COMMAND)
local COMMAND_AMMO = table.Copy(COMMAND)

COMMAND_ALL.StripFunction = player_meta.RemoveAllItems
COMMAND_AMMO.StripFunction = player_meta.StripAmmo

--registration
PYRITION:ConsoleCommandRegister("strip", COMMAND)
PYRITION:ConsoleCommandRegister("strip all", COMMAND_ALL)
PYRITION:ConsoleCommandRegister("strip ammo", COMMAND_AMMO)