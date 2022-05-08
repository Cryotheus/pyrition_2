--console commands
concommand.Add("pyrition", function(ply, command, arguments)
	local arguments_count = #arguments
	local command, depth = PYRITION:ConsoleCommandGet(arguments, true)
	
	if depth == 0 then PYRITION:LanguageQueue(ply, "pyrition.unknown.command")
	else
		local subbed_arguments = {}
		
		for index = depth + 1, arguments_count do table.insert(subbed_arguments, arguments[index]) end
		
		local success, message, phrases = PYRITION:ConsoleCommandExecute(ply, command, unpack(subbed_arguments))
		
		PYRITION:LanguageQueue(ply, message, table.Merge({player = ply:Name()}, phrases or {}))
	end
end, function(command, arguments_string)
	if SERVER then return {"The server does not have auto-completes."} end
	
	return PYRITION:ConsoleComplete(command, arguments_string)
end, SERVER and "Master command for Pyrition" or "Master command for Pyrition (SERVER)")