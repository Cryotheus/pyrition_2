--TODO: commands
--bring
--cleanup
--freeze
--god
--goto
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
function COMMAND:Execute(ply, targetting)
	local target, message = PYRITION:PlayerFind(targetting, ply, true)
	
	if target then
		--target
		local landings, landing_count = PYRITION:PlayerLanding(target, {ply})
		
		if landing_count == 1 then
			ply:SetPos(landings[1])
			
			return true, "pyrition.commands.goto.success", {target = target:Name()}
		end
		
		return false, "pyrition.player.landing"
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("goto", COMMAND)