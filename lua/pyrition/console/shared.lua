--local functions
local function command_callback(ply, command, arguments)
	local arguments_count = #arguments
	local command, depth = PYRITION:ConsoleCommandGet(arguments, true)
	
	if depth == 0 then PYRITION:LanguageQueue(ply, "pyrition.command.unknown")
	else
		local subbed_arguments = {}
		
		for index = depth + 1, arguments_count do table.insert(subbed_arguments, arguments[index]) end
		
		local success, message, phrases = PYRITION:ConsoleCommandExecute(ply, command, unpack(subbed_arguments))
		
		if message then PYRITION:LanguageQueue(ply, message, table.Merge({player = ply:Name()}, phrases or {}))
		elseif not success then PYRITION:LanguageQueue(ply, "pyrition.command.failed", table.Merge({command = table.concat(command, " ")}, phrases or {})) end
	end
end

--pyrition functions
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