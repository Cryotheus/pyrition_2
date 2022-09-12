--locals
local COMMAND = {
	Arguments = {
		Required = 1,
		
		{
			Class = "Player",
			Single = true
		}
	}
}

--command function
function COMMAND:Execute(ply, target)
	local landings, landing_count = PYRITION:PlayerLanding(target, {ply})
	
	if landing_count == 1 then
		PYRITION:PlayerTeleport(ply, landings[1], "goto", target)
		
		return true, "pyrition.commands.goto.success", {target = target}
	end
	
	return false, "pyrition.player.landing.fail"
end

--post
PYRITION:ConsoleCommandRegister("goto", COMMAND)