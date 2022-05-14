local COMMAND = {
	Arguments = {
		Required = 2,
		
		{Type = "Player"},
		
		{
			Single = true,
			Type = "Player"
		}
	}
}
--local COMMAND_FORCED = {}

--command function
--(needle, supplicant, single, exclude_supplicant)
function COMMAND:Execute(ply, traveller_targetting, targetting)
	local target, message = PYRITION:PlayerFind(targetting, ply, true)
	local travellers, message = PYRITION:PlayerFind(traveller_targetting, ply, false)
	
	print(target, message)
	print(travellers, message)
	
	if target and travellers then
		local landings, landing_count = PYRITION:PlayerLanding(target, travellers)
		
		if landing_count == #travellers then
			for index, target in ipairs(travellers) do target:SetPos(landings[index]) end
			
			return true, "[:player] sent [:travellers] to [:target].", {target = target:Name(), travellers = travellers}
		else return false, "pyrition.player.landing.insufficient" end
		
		return false, "pyrition.player.landing.fail"
	end
	
	return false, message
end

--local COMMAND_FORCED = table.Copy(COMMAND)

--post
PYRITION:ConsoleCommandRegister("send", COMMAND)
--PYRITION:ConsoleCommandRegister("send force", COMMAND_FORCED)