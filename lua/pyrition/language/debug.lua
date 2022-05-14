--this is for debugging! in the official release we should be using localization files
local forced = {
	["player.landing.insufficient"] = "Not enough space.",
	["command.failed.required_arguments"] = 'Execution of the "[:command]" command failed, you must provide at least [:count] arguments.',
	["command.failed.required_arguments.singular"] = 'Execution of the "[:command]" command failed, arguments are required.',
	["commands.send"] = "Send",
	["commands.send.description"] = "Teleport players to another player.",
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end