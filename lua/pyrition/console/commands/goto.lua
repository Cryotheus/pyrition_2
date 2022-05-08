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
function COMMAND:Execute(ply, targetting, reason)
	if not targetting then return false, "pyrition.player.find.targetless" end
	
	local target, message = PYRITION:PlayerFind(targetting, ply, true)
	
	if target then
		--target
		
		return true, "pyrition.commands.goto.success", {target = target:Name()}
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("goto", COMMAND)