--locals
local COMMAND_LIST_QUEUED = {
	Arguments = false,
	Console = true
}

--command function
function COMMAND_LIST_QUEUED:Execute(ply)
	local threads = PYRITION.SQLCoroutines
	
	if table.IsEmpty(threads) then return false, "No threads active." end
	
	PYRITION:LanguageQueue(ply, "SQL transaction list")
	
	for thread, queued in pairs(threads) do
		PYRITION:LanguageQueue(ply, "[:thread]: [:count] active", {
			thread = string.sub(tostring(thread), 9),
			count = tostring(#queued)
		}, option)
	end
	
	return true, false
end

--registration
PYRITION:ConsoleCommandRegister("sql list queued", COMMAND_LIST_QUEUED)