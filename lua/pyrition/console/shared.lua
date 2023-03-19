--locals
local function create_master_command(command_name, help, no_fail_response)
	concommand.Add(command_name, function(ply, _command, arguments)
		local command = PYRITION:ConsoleParseArguments(arguments)

		if command then

		elseif no_fail_response then return
		else PYRITION:LanguageQueue(ply, "pyrition.command.unknown") end
	end, function(_command, arguments_string)
		local _arguments = PYRITION:ConsoleParseString(arguments_string)


	end, language.GetPhrase(help or "pyrition.command.help"))
end

--globals

--pyrition functions
function PYRITION:ConsoleParseArguments(arguments)
	local command_path_count = 0
	local tree = self.ConsoleCommandSignatureTree

	for index, argument in ipairs(arguments) do
		if string.find(argument, "%s") then break end

		local branch = tree[argument]

		if not branch then break end

		command_path_count = command_path_count + 1
		tree = branch

		--nothing beyond here is part of the command path
		if argument[-1] == "?" then break end
	end

	print("printing tree")
	PrintTable(tree)

	print("command_path_count: " .. command_path_count)
	print("signatures: <" .. table.concat(tree, ">-<") .. ">")
end

function PYRITION:ConsoleParseString(arguments_string)
	local arguments = {}
	local in_string = false
	local quote_count = select(2, string.gsub(arguments_string, "\"", "\"")) or 0

	if quote_count % 2 == 1 then arguments_string = arguments_string .. "\"" end

	arguments_string = string.gsub(arguments_string, "\"\"+", function(match) return string.sub(string.rep("\" ", #match), 1, -2) end)

	for match in string.gmatch(arguments_string, ".-\"") do
		match = string.sub(match, 1, -2)

		if in_string then
			in_string = false

			table.insert(arguments, match == " " and "" or match)
		else
			in_string = true
			local match = string.Trim(match)

			if match ~= "" then table.Add(arguments, string.Explode("%s+", match, true)) end
		end
	end

	for index, argument in ipairs(arguments) do print(index .. " <" .. argument .. ">") end

	return arguments
end

--pyrition hooks
function PYRITION:PyritionConsoleComplete(_executor, _arguments)

end

function PYRITION:PyritionConsoleExecute(executor, _arguments)
	if SERVER and executor:IsValid() then
		if executor:IsListenServerHost() then executor = game.GetWorld()
		else return false, "Only the server can run commands server side." end
	end

end

--commands
if SERVER and (game.SinglePlayer() or not game.IsDedicated()) then
	create_master_command("sv_pyrition")
	create_master_command("sv_pyrition_nfr", "pyrition.command.help.nfr", true)
else
	create_master_command("pyrition")
	create_master_command("pyrition_nfr", "pyrition.command.help.nfr", true)

	--hee hee hee haw |\/\/|
	create_master_command("ulx", "pyrition.command.help.ulx")
end

if CLIENT then
	create_master_command("cl_pyrition")
	create_master_command("cl_pyrition_nfr", "pyrition.command.help.nfr", true)
end

concommand.Add("d", function(_ply, _command, arguments, arguments_string)
	print("arguments_string:\n<" .. arguments_string .. ">")

	for index, argument in ipairs(arguments) do print(index .. " <" .. argument .. ">") end
end)