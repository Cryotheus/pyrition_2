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
	
	repeat table.insert(arguments, net.ReadString())
	until not net.ReadBool()
	
	local command = PYRITION:ConsoleCommandGetExisting(parents)
	
	if command then
		local success, message, phrases = PYRITION:ConsoleCommandExecute(ply, command, unpack(arguments))
		
		PYRITION:LanguageQueue(ply, message, table.Merge({player = ply:Name()}, phrases or {}))
	else PYRITION:LanguageQueue(ply, "pyrition.unknown.command") end
end)

--post
PYRITION:NetAddEnumeratedString("command")