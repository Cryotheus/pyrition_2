local entity_meta = FindMetaTable("Entity")
local player_meta = FindMetaTable("Player")

local function register(name, get_method, set_method)
	--registers a method for "command integer" and "command player integer"
	--"command integer"
	PYRITION:CommandRegister(name, {
		Arguments = {"Integer Minimum = 1 Maximum = 2147483647"},
		Console = true,

		Execute = function(_self, executor, value)
			if executor:Alive() and get_method(executor) ~= value then
				set_method(executor, value)

				return true, {targets = {executor, IsPlayerList = true}}
			end

			return false, nil, PYRITION_COMMAND_MISSED
		end
	})

	--"command player integer"
	PYRITION:CommandRegister(name, {
		Arguments = {"Player", "Integer Minimum = 1 Maximum = 2147483647"},
		Console = true,

		Execute = function(_self, _executor, targets, value)
			local modified_targets = {IsPlayerList = true}

			for index, target in ipairs(targets) do
				if target:Alive() and get_method(target) ~= value then
					set_method(target, value)

					table.insert(modified_targets, target)
				end
			end

			if modified_targets[1] then return true, {targets = modified_targets}
			else return false, nil, PYRITION_COMMAND_MISSED end
		end
	})
end

register("Armor", player_meta.Armor, player_meta.SetArmor)
register("ArmorMax", player_meta.GetMaxArmor, player_meta.SetMaxArmor)
register("Health", entity_meta.Health, entity_meta.SetHealth)
register("HealthMax", entity_meta.GetMaxHealth, entity_meta.SetMaxHealth)