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