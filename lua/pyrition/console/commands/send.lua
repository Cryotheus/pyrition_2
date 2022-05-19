local COMMAND = {
	Arguments = {
		Required = 2,
		
		{Class = "Player"},
		
		{
			Single = true,
			Class = "Player"
		}
	}
}

--local COMMAND_FORCED = {}

--command function
function COMMAND:Execute(ply, traveller_targetting, targetting)
	local target, message = PYRITION:PlayerFind(targetting, ply, true)
	local travellers, message = PYRITION:PlayerFind(traveller_targetting, ply, false)
	
	if target and travellers then
		local landings, landing_count = PYRITION:PlayerLanding(target, travellers)
		
		if landing_count == #travellers then
			for index, traveller in ipairs(travellers) do PYRITION:PlayerTeleport(traveller, landings[index], "send", target:Name()) end
			
			return true, "pyrition.commands.send.success", {target = target:Name(), targets = travellers}
		else return false, "pyrition.player.landing.insufficient" end
		
		return false, "pyrition.player.landing.fail"
	end
	
	return false, message
end

--local COMMAND_FORCED = table.Copy(COMMAND)

--post
PYRITION:ConsoleCommandRegister("send", COMMAND)
--PYRITION:ConsoleCommandRegister("send force", COMMAND_FORCED)