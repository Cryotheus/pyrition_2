local COMMAND = {Arguments = {{Type = "Player"}}}

--local functions
local function is_noclipped(ply) return ply:GetMoveType() == MOVETYPE_NOCLIP end
--noclip
--command functions
function COMMAND:Execute(ply, targetting)
	local targets, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		local noclip = self.Noclip
		local noclipped = {}
		
		if noclip == nil then noclip = not is_noclipped(ply) and true or false end
		
		local move_type = noclip and MOVETYPE_NOCLIP or MOVETYPE_WALK
		
		for index, target in ipairs(targets) do
			if target:Alive() and noclip ~= is_noclipped(target) then
				target:SetMoveType(move_type)
				
				table.insert(noclipped, target)
			end
		end
		
		if #noclipped == 0 then return false, noclip and "pyrition.commands.noclip.enable.missed" or "pyrition.commands.noclip.disable.missed" end
		
		return true, noclip and "pyrition.commands.noclip.enable.success" or "pyrition.commands.noclip.disable.success", {targets = noclipped}
	end
	
	return false, message
end

--post
PYRITION:ConsoleCommandRegister("noclip", COMMAND)
PYRITION:ConsoleCommandRegister("noclip enable", table.Merge({Noclip = false}, COMMAND))
PYRITION:ConsoleCommandRegister("noclip disable", table.Merge({Noclip = true}, COMMAND))