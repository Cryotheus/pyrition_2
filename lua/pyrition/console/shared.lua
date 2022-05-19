--local functions
local function command_callback(ply, command, arguments)
	local arguments_count = #arguments
	local command, depth = PYRITION:ConsoleCommandGet(arguments, true)
	
	if depth == 0 then PYRITION:LanguageQueue(ply, "pyrition.command.unknown")
	else
		local subbed_arguments = {}
		
		for index = depth + 1, arguments_count do table.insert(subbed_arguments, arguments[index]) end
		
		PYRITION:ConsoleExecute(ply, command, subbed_arguments)
	end
end

local function command_localization(command) return "#pyrition.commands." .. table.concat(command.Parents, ".") end

--pyrition functions
function PYRITION:ConsoleExecute(ply, command, arguments)
	local command_arguments = command.Arguments or {}
	local required = command_arguments.Required or 0
	
	if #arguments < required then
		if required == 1 then PYRITION:LanguageQueue(ply, "pyrition.command.failed.required_arguments.singular", {command = command_localization(command)})
		else PYRITION:LanguageQueue(ply, "pyrition.command.failed.required_arguments", {command = command_localization(command), count = required}) end
		
		return false
	end
	
	local success, message, phrases = PYRITION:ConsoleCommandExecute(ply, command, unpack(arguments))
		
	if message then PYRITION:LanguageQueue(success or ply, message, table.Merge({executor = ply:Name()}, phrases or {}))
	elseif success then
		if not command.Downloaded then
			--we don't send a message for downloaded commands
			PYRITION:LanguageQueue(ply, "pyrition.command.success", {command = command_localization(command)})
		end
	else PYRITION:LanguageQueue(ply, "pyrition.command.failed", {command = command_localization(command)}) end
	
	return success
end

function PYRITION:ConsoleParseArguments(arguments_string)
	--parse a chat message that we know is a command
	local building
	local arguments = {}
	
	--Lua's patterns are too limited, so we make our own matcher
	for index, word in ipairs(string.Explode("%s", arguments_string, true)) do
		if building then --we're creating a string with spaces in it so we can add it to the list
			if string.EndsWith(word, '"') then
				table.insert(arguments, building .. " " .. string.sub(word, 1, -2))
				
				building = nil
			else building = building .. " " .. word end
		elseif word == '"' then building = "" --we need to build a string with spaces in it
		elseif string.StartWith(word, '"') then --we need to build a string with spaces in it starting with this word, unless it ends at this word
			if string.EndsWith(word, '"') then table.insert(arguments, string.sub(word, 2, -2))
			else building = string.sub(word, 2) end
		elseif word ~= "" then  table.insert(arguments, word) end --we should add the word to the list
	end
	
	return arguments
end

--console commands
if game.SinglePlayer() then
	if SERVER then concommand.Add("sv_pyrition", command_callback, function() return {"The server cannot use autocompletion."} end, "Master command for Pyrition (server sided for single-player, not available in a networked game)")
	else concommand.Add("pyrition", command_callback, function(command, arguments_string) return PYRITION:ConsoleComplete(command, arguments_string) end, PYRITION:LanguageTranslate("pyrition.command.help", "Master command for Pyrition (fall back)")) end
else
	concommand.Add("pyrition", command_callback, function(command, arguments_string)
		if SERVER then return end
		
		return PYRITION:ConsoleComplete(command, arguments_string)
	end, PYRITION:LanguageTranslate("pyrition.command.help", "Master command for Pyrition (fall back)"))
end