util.AddNetworkString("pyrition_command")

--hooks
hook.Add("PyritionConsoleCommandRegister", "PyritionConsole", function(parents, command, base_parents)
	if isstring(parents) then parents = string.Split(parents, " ") end
	
	PYRITION:NetAddEnumeratedString("command", parents)
end)

--net
net.Receive("pyrition_command", function(length, ply)
	local arguments = {}
	local parents = {}
	
	repeat table.insert(parents, PYRITION:NetReadEnumeratedString("command", ply))
	until not net.ReadBool()
	
	while net.ReadBool() do table.insert(arguments, net.ReadString()) end
	
	local command = PYRITION:ConsoleCommandGetExisting(parents)
	
	if command then
		local success, message, phrases = PYRITION:ConsoleCommandExecute(ply, command, unpack(arguments))
		
		if message then PYRITION:LanguageQueue(ply, message, table.Merge({player = ply:Name()}, phrases or {}))
		elseif not success then PYRITION:LanguageQueue(ply, "pyrition.command.failed", table.Merge({command = table.concat(command, " ")}, phrases or {})) end
	else PYRITION:LanguageQueue(ply, "pyrition.command.unknown") end
end)

--post
PYRITION:NetAddEnumeratedString("command")