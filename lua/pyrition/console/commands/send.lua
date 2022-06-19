local COMMAND = {
	Arguments = {
		Required = 2,
		
		{Class = "Player"},
		
		{
			Single = true,
			Class = "Player"
		}
	},
	
	Console = true
}

--local COMMAND_FORCED = {}

--command function
function COMMAND:Execute(ply, travellers, target)
	if #travellers == 1 and travellers[1] == target then return false, "pyrition.commands.send.fail.self" end
	
	local landings, landing_count = PYRITION:PlayerLanding(target, travellers)
	
	if landing_count == #travellers then
		for index, traveller in ipairs(travellers) do PYRITION:PlayerTeleport(traveller, landings[index], "send", target) end
		
		return true, "pyrition.commands.send.success", {target = target, targets = travellers}
	else return false, "pyrition.player.landing.insufficient" end
	
	return false, "pyrition.player.landing.fail"
end

--local COMMAND_FORCED = table.Copy(COMMAND)

--post
PYRITION:ConsoleCommandRegister("send", COMMAND)
--PYRITION:ConsoleCommandRegister("send force", COMMAND_FORCED)