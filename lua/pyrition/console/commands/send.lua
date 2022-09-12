--locals
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

--command function
function COMMAND:Execute(_ply, travellers, target)
	if #travellers == 1 and travellers[1] == target then return false, "pyrition.commands.send.fail.self" end
	
	local landings, landing_count = PYRITION:PlayerLanding(target, travellers, self.Force)
	
	if landing_count == #travellers then
		for index, traveller in ipairs(travellers) do PYRITION:PlayerTeleport(traveller, landings[index], "send", target) end
		
		--since we also register send force with this method, we must specify that it uses the send command's success phrase instead
		return true, "pyrition.commands.send.success", {target = target, targets = travellers}
	else return false, "pyrition.player.landing.insufficient" end
	
	return false, "pyrition.player.landing.fail"
end

--post
PYRITION:ConsoleCommandRegister("send", COMMAND)
PYRITION:ConsoleCommandRegister("send force", table.Merge({Force = true}, COMMAND))