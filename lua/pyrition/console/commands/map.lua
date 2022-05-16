local COMMAND = {
	Arguments = {
		Required = 1,
		
		{Class = "Map"}
	}
}

local COMMAND_VOTE = {
	Arguments = {
		Required = 1,
		
		{Class = "Map"}
	}
}

local COMMAND_VOTE_ANNUL = {
	Arguments = {
		Required = 1,
		
		{Class = "Map"}
	}
}

local COMMAND_VOTE_RETRACT = {Arguments = {{Class = "Player"}}}

--locals
local maps = PYRITION.MapList

--command functions
function COMMAND:Execute(ply, map_name)
	if maps[map_name] then
		PYRITION:MapChange(map_name)
		
		return true, "pyrition.commands.map.success"
	end
	
	return false, "pyrition.commands.map.fail"
end

function COMMAND_VOTE:Execute(ply, map_name)
	if maps[map_name] then
		local success, message = PYRITION:MapVote(ply, map_name)
		
		return success, message or "pyrition.commands.map.vote.success", {map = map_name}
	end
	
	return false, "pyrition.commands.map.fail"
end

function COMMAND_VOTE_ANNUL:Execute(ply, map_name)
	if maps[map_name] then
		local victims = PYRITION:MapVoteAnnul(map_name)
		
		if #victims == 0 then return false, "pyrition.commands.map.vote.annul.missed" end
		
		return true, "pyrition.commands.map.vote.annul.success", {map = map_name, victims = victims}
	end
	
	return false, "pyrition.commands.map.fail"
end

function COMMAND_VOTE_RETRACT:Execute(ply, targetting)
	local targets = PYRITION:PlayerFindWithFallback(targetting, ply, ply)
	
	if targets then
		if #targets == 1 and ply == targets[1] then
			if PYRITION:MapVoteRetract(ply) then return true, "pyrition.commands.map.vote.retract.success.self" end
			
			return false, "pyrition.commands.map.vote.retract.fail"
		end
		
		local victims = {IsPlayerList = true}
		
		for index, target in ipairs(targets) do if PYRITION:MapVoteRetract(target) then table.insert(victims, target) end end
		
		return true, "pyrition.commands.map.vote.retract.success", {victims = victims}
	end
	
	return false, "pyrition.player.find.invalid"
end

--post
PYRITION:ConsoleCommandRegister("map", COMMAND)
PYRITION:ConsoleCommandRegister("map vote", COMMAND_VOTE)
PYRITION:ConsoleCommandRegister("map vote annul", COMMAND_VOTE_ANNUL)
PYRITION:ConsoleCommandRegister("map vote retract", COMMAND_VOTE_RETRACT)