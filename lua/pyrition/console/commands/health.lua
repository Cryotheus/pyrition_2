local COMMAND = {}
local entity_meta = FindMetaTable("Entity")
local player_meta = FindMetaTable("Player")

--custom fields
COMMAND.SetFunction = entity_meta.SetHealth

--command functions
function COMMAND:Execute(ply, targetting, amount)
	if not targetting then return false, "pyrition.commands.health.empty" end
	
	local message
	local targets = {ply}
	
	if amount == nil then amount = targetting
	else targets, message = PYRITION:PlayerFind(targetting, ply) end
	if not targets then return false, message end
	
	local amount = tonumber(amount)
	
	if amount then
		local modified = {IsPlayerList = true}
		local set_function = self.SetFunction
		
		for index, target in ipairs(targets) do
			if target:Alive() then
				set_function(target, amount)
				table.insert(modified, target)
			end
		end
		
		if table.IsEmpty(modified) then return false, "pyrition.commands.health.missed" end
		
		return true, "pyrition.commands.health.success", {targets = modified}
	end
	
	return false, "pyrition.commands.health.fail"
end

--post
local COMMAND_ARMOR = table.Copy(COMMAND)
local COMMAND_ARMOR_MAX = table.Copy(COMMAND)
local COMMAND_MAX = table.Copy(COMMAND)

COMMAND_ARMOR.SetFunction = player_meta.SetArmor
COMMAND_ARMOR_MAX.SetFunction = player_meta.SetMaxArmor
COMMAND_MAX.SetFunction = entity_meta.SetMaxHealth

--registration
print("1:", PYRITION:ConsoleCommandRegister("armor", COMMAND_ARMOR))
print("2:", PYRITION:ConsoleCommandRegister("armor max", COMMAND_ARMOR_MAX))
print("3:", PYRITION:ConsoleCommandRegister("health", COMMAND))
print("4:", PYRITION:ConsoleCommandRegister("health max", COMMAND_MAX))