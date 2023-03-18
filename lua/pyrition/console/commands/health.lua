--locals
local entity_meta = FindMetaTable("Entity")
local player_meta = FindMetaTable("Player")

--local functions
local function create_command_table(set_function)
	return {
		Arguments = {
			{
				Required = 2,

				"Player",
				"Integer Maximum = 2147483647 Minimum = 1",
			},

			{
				Required = 1,
				Setup = function(ply, amount) return {ply}, amount end,

				"Integer Maximum = 2147483647 Minimum = 1"
			}
		},

		Console = true,

		Execute = function(_ply, targets, amount)
			local modified_targets = {}

			for index, target in ipairs(targets) do
				if target:Alive() then
					set_function(target, amount)
					table.insert(modified_targets)
				end
			end

			if modified_targets[1] then return true, {targets = modified_targets}
			else return false, nil, PYRITION_COMMAND_MISSED end
		end
	}
end

--post
PYRITION:ConsoleCommandRegister("armor max", create_command_table(player_meta.SetMaxArmor))
PYRITION:ConsoleCommandRegister("armor", create_command_table(player_meta.SetArmor))
PYRITION:ConsoleCommandRegister("health max", create_command_table(entity_meta.SetMaxHealth))
PYRITION:ConsoleCommandRegister("health", create_command_table(entity_meta.SetHealth))