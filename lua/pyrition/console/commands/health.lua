--locals
local COMMAND = {
	Arguments = {
		Required = 1,
		
		{
			Class = "Player",
			Default = true,
			Optional = true
		},
		
		{
			Class = "Integer",
			Default = 100,
			Maximum = 2 ^ 31 - 1,
			Minimum = 1
		}
	},
	
	Console = true
}

local entity_meta = FindMetaTable("Entity")
local player_meta = FindMetaTable("Player")

--custom fields
COMMAND.SetFunction = entity_meta.SetHealth

--command functions
function COMMAND:Execute(_ply, targets, amount)
	local modified = {IsPlayerList = true}
	local set_function = self.SetFunction
	
	for index, target in ipairs(targets) do
		if target:Alive() then
			set_function(target, amount)
			table.insert(modified, target)
		end
	end
	
	if table.IsEmpty(modified) then return false, "pyrition.commands.health.missed" end
	
	return true, nil, {amount = tostring(amount), targets = modified}
end

--post
local COMMAND_ARMOR = table.Copy(COMMAND)
local COMMAND_ARMOR_MAX = table.Copy(COMMAND)
local COMMAND_MAX = table.Copy(COMMAND)

COMMAND_ARMOR.SetFunction = player_meta.SetArmor
COMMAND_ARMOR_MAX.SetFunction = player_meta.SetMaxArmor
COMMAND_MAX.SetFunction = entity_meta.SetMaxHealth

--registration
PYRITION:ConsoleCommandRegister("armor", COMMAND_ARMOR)
PYRITION:ConsoleCommandRegister("armor max", COMMAND_ARMOR_MAX)
PYRITION:ConsoleCommandRegister("health", COMMAND)
PYRITION:ConsoleCommandRegister("health max", COMMAND_MAX)