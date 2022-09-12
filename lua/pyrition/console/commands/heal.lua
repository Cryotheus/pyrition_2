--locals
local COMMAND = {
	Arguments = {"Player"},
	Console = true
}

--command function
function COMMAND:Execute(_ply, targets)
	for index, target in ipairs(targets) do
		target:Extinguish()
		
		if target:Alive() then
			local armor = target:Armor()
			local max_health = target:GetMaxHealth()
			
			if target:Health() < max_health then target:SetHealth(max_health) end
			
			if armor > 0 then
				local max_armor = target:GetMaxArmor()
				
				if armor < max_armor then target:SetArmor(max_armor) end
			end
		else target:Spawn() end
	end
	
	return true, nil, {targets = targets}
end

--registration
PYRITION:ConsoleCommandRegister("heal", COMMAND)