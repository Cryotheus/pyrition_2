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
	
	if command then PYRITION:ConsoleExecute(ply, command, arguments)
	else PYRITION:LanguageQueue(ply, "pyrition.command.unknown") end
end)

--post
PYRITION:NetAddEnumeratedString("command")