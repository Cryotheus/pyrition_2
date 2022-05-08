local COMMAND = {}
local player_meta = FindMetaTable("Player")

--command function
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	print("so flay", type(targetting), targetting)
	print("msg", targets, message)
	
	if targets then
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
		
		return true, "pyrition.commands.heal.success", {targets = targets}
	end
	
	return false, message
end

--registration
PYRITION:ConsoleCommandRegister("heal", COMMAND)