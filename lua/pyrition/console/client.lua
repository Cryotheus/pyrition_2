--pyrition hooks
function PYRITION:PyritionConsoleComplete(command, arguments_string)
	--more!
	return {command .. " " .. arguments_string .. " pls pogram", "work in progress"}
end