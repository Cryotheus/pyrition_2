--locals
local COMMAND = {
	Arguments = {
		Required = 1,
		
		{
			Selfless = true,
			Class = "Player"
		}
	}
}

--command function
function COMMAND:Execute(ply, targets)
	local landings, landing_count = PYRITION:PlayerLanding(ply, targets, self.Force)
	
	if landing_count == #targets then
		for index, target in ipairs(targets) do PYRITION:PlayerTeleport(target, landings[index], "bring", ply) end
		
		--since we also register bring force with this method, we must specify that it uses the bring command's success phrase instead
		return true, "pyrition.commands.bring.success", {targets = targets}
	else return false, "pyrition.player.landing.insufficient" end
	
	return false, "pyrition.player.landing.fail"
end

--post
PYRITION:ConsoleCommandRegister("bring", COMMAND)
PYRITION:ConsoleCommandRegister("bring force", table.Merge({Force = true}, COMMAND))