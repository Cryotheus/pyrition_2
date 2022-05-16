local COMMAND = {
	Arguments = {
		Required = 1,
		
		{
			Selfless = true,
			Class = "Player"
		}
	},
	
	Force = false
}

--command function
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFind(targetting, ply, false, true)
	
	if targets then
		local landings, landing_count = PYRITION:PlayerLanding(ply, targets, self.Force)
		
		if landing_count == #targets then
			for index, target in ipairs(targets) do PYRITION:PlayerTeleport(target, landings[index], "bring", ply:Name()) end
			
			return true, "pyrition.commands.bring.success", {targets = targets}
		else return false, "pyrition.player.landing.insufficient" end
		
		return false, "pyrition.player.landing.fail"
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("bring", COMMAND)
PYRITION:ConsoleCommandRegister("bring force", table.Merge({Force = true}, COMMAND))