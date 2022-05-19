local COMMAND = {
	Arguments = {
		Required = 0,
		
		{Class = "Player"},
		
		{
			Default = 0,
			Minimum = 0,
			Class = "Integer"
		}
	}
}

--command function
function COMMAND:Execute(ply, targetting, damage)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		local damage = tonumber(damage)
		local slapped = {IsPlayerList = true}
		
		if damage then
			math.max(damage, 0)
			
			if damage == 0 then damage = false end
		end
		
		for index, target in ipairs(targets) do
			--you can slap dead people :)))
			--correction: that's on the TODO list, you WILL be able to slap people once I make shared player ragdolls
			if PYRITION:PlayerSlap(target, true, damage or false, true) then table.insert(slapped, target) end
		end
		
		if #slapped == 0 then return false, "pyrition.commands.slap.missed" end
		
		return true, "pyrition.commands.slap.success", {targets = slapped}
	end
	
	return false, message
end

--registration
PYRITION:ConsoleCommandRegister("slap", COMMAND)