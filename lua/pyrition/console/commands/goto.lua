local COMMAND = {}

--command function
function COMMAND:Execute(ply, targetting)
	local target, message = PYRITION:PlayerFind(targetting, ply, true, true)
	
	if target then
		local landings, landing_count = PYRITION:PlayerLanding(target, {ply})
		
		if landing_count == 1 then
			PYRITION:PlayerTeleport(ply, landings[1], "goto", target:Name())
			
			return true, "pyrition.commands.goto.success", {target = target:Name()}
		end
		
		return false, "pyrition.player.landing.fail"
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("goto", COMMAND)