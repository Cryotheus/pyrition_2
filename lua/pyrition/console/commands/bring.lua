local COMMAND = {}
local COMMAND_FORCED = {}

--command function
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFind(targetting, ply, false, true)
	
	if targets then
		local landings, landing_count = PYRITION:PlayerLanding(ply, targets)
		
		if landing_count == #targets then
			for index, target in ipairs(targets) do target:SetPos(landings[index]) end
			
			return true, "pyrition.commands.bring.success", {targets = targets}
		else return false, "pyrition.player.landing.insufficient" end
		
		return false, "pyrition.player.landing.fail"
	end
	
	return false, message
end

local COMMAND_FORCED = table.Copy(COMMAND)

--post
PYRITION:ConsoleCommandRegister("bring", COMMAND)
PYRITION:ConsoleCommandRegister("bring force", COMMAND_FORCED)