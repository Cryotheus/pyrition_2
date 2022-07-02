--hooks
hook.Add("PyritionConsoleCommandRegister", "PyritionConsole", function(parents)
	if isstring(parents) then parents = string.Split(parents, " ") end
	
	PYRITION:NetAddEnumeratedString("command", parents)
end)

--post
PYRITION:NetAddEnumeratedString("command")