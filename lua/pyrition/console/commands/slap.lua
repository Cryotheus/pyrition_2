--TODO: commands
--cleanup
--freeze
--god
--jail
--map
--message
--noclip
--return
--send
--slap
--strip
--who
local COMMAND = {}

--command function
function COMMAND:Execute(ply, targetting, damage)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		local slapped = {IsPlayerList = true}
		
		for index, target in ipairs(targets) do
			if target:Alive() then
				slap(target)
				if PYRITION:PlayerSlap(ply, true, false) then
					table.insert(slapped, target) end
			end
		end
		
		if table.IsEmpty(slapped) then return false, "No living targets to slap." end
		
		return true, "[:player] slapped [:targets].", {targets = slapped}
	end
	
	return false, message
end

--registration
PYRITION:ConsoleCommandRegister("slap", COMMAND)