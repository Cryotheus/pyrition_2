--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses or {}
local is_pyrition_command
local is_pyrition_command_indexable
local is_pyrition_command_organizer
local phrase_exists = PYRITION._LanguagePhraseExists

--local functions
local function command_callback(ply, arguments, no_fail_response)
	local arguments_count = #arguments
	local command, depth = PYRITION:ConsoleCommandGet(arguments, true)
	local ply = ply:IsValid() and ply or game.GetWorld()
	
	if not command or command == PYRITION.ConsoleCommands then PYRITION:LanguageQueue(ply, "pyrition.command.unknown")
	elseif is_pyrition_command_organizer(command) then PYRITION:LanguageQueue(ply, "pyrition.command.unknown.organizer")
	else
		local subbed_arguments = {}
		
		for index = depth + 1, arguments_count do table.insert(subbed_arguments, arguments[index]) end
		
		PYRITION:ConsoleExecute(ply, command, subbed_arguments, no_fail_response)
	end
end

local function command_localization(command) return "#pyrition.commands." .. table.concat(command.Parents, ".") end

local function create_master_command(command_name, help, no_fail_response)
	concommand.Add(
		command_name,
		function(ply, _command, arguments) command_callback(ply, arguments, no_fail_response) end,
		function(command, arguments_string) return PYRITION:ConsoleComplete(command .. " ", arguments_string) end,
		language.GetPhrase(help or "pyrition.command.help")
	)
end

local function insert_prefixed_commands(completions, tree, validation_prefix, command_prefix)
	for name, command in pairs(tree) do
		--if it's indexable and it's prefixed by validation_prefix, append to completions
		if string.StartWith(name, validation_prefix) and is_pyrition_command_indexable(command) then table.insert(completions, command_prefix .. name) end
	end
end

function is_pyrition_command(object) return istable(object) and object.IsPyritionCommand or false end

function is_pyrition_command_indexable(object)
	if istable(object) then return object.IsPyritionCommand or object.IsPyritionCommandOrganizer end
	
	return false
end

function is_pyrition_command_organizer(object)
	if istable(object) then return not object.IsPyritionCommand and object.IsPyritionCommandOrganizer end
	
	return false
end

--globals
PYRITION.ConsoleCommandArgumentClasses = command_argument_classes
PYRITION._IsPyritionCommand = is_pyrition_command
PYRITION._IsPyritionCommandIndexable = is_pyrition_command_indexable
PYRITION._IsPyritionCommandOrganizer = is_pyrition_command_organizer

--pyrition functions
function PYRITION:ConsoleExecute(ply, command, arguments, no_fail_response)
	local arguments = arguments or {}
	local command_arguments = command.Arguments or {}
	local filter_success, fail_index, fail_message
	local required = command_arguments.Required or 0
	
	ply = IsValid(ply) and ply or game.GetWorld()
	
	if ply == game.GetWorld() and not command.Console then
		--we shouldn't let the console run commands that are not marked as console safe
		return self:LanguageQueue(ply, "pyrition.command.failed.console", {command = command_localization(command)})
	end
	
	if #arguments < required then
		if required == 1 then self:LanguageQueue(ply, "pyrition.command.failed.required_arguments.singular", {command = command_localization(command)})
		else self:LanguageQueue(ply, "pyrition.command.failed.required_arguments", {command = command_localization(command), count = required}) end
		
		return false
	end
	
	--if we don't have the command send it to the server for execution
	if CLIENT and command.Downloaded then
		PYRITION:ConsoleCommandSend(command, arguments, ply)
		
		return true
	else filter_success, fail_index, fail_message = self:ConsoleCommandArgumentValidate(ply, command, arguments) end
	
	if filter_success then
		local success, message, phrases = self:ConsoleCommandExecute(ply, command, arguments)
		
		--if we failed and we have failed execution response disabled, stop here
		if not success and no_fail_response then return false end
		
		local success_targets = command.SilentResponse and ply or success or ply
		
		if message then
			self:LanguageQueue(
				success_targets,
				message,
				table.Merge(
					{executor = ply},
					phrases or {}
				)
			)
		elseif success then
			--we don't send a message for downloaded commands
			if command.Downloaded then return success end
			
			local language_key = "pyrition.commands." .. table.concat(command.Parents, ".") .. ".success"
			
			if phrase_exists(language_key) then return self:LanguageQueue(success_targets, language_key, table.Merge({executor = ply}, phrases or {})) end
			
			self:LanguageQueue(success_targets, "pyrition.command.success", {command = command_localization(command)})
		else self:LanguageQueue(ply, "pyrition.command.failed", {command = command_localization(command)}) end
		
		return success
	elseif not no_fail_response then
		self:LanguageQueue(ply, fail_message and "pyrition.command.failed.argument.detailed" or "pyrition.command.failed.argument", {
			class = (command_arguments[fail_index] or {Class = "nil"}).Class,
			command = command_localization(command),
			index = "#" .. tostring(fail_index or -1),
			message = "#" .. tostring(fail_message or "nil")
		})
	end
	
	return false
end

function PYRITION:ConsoleParseArguments(arguments_string)
	--parse a chat message that we know is a command
	local building
	local arguments = {}
	
	--Lua's patterns are too limited, so we make our own matcher
	for index, word in ipairs(string.Explode("%s", arguments_string, true)) do
		if building then --we're creating a string with spaces in it so we can add it to the list
			if string.EndsWith(word, '"') then
				table.insert(arguments, building .. " " .. string.sub(word, 1, -2))
				
				building = nil
			else building = building .. " " .. word end
		elseif word == '"' then building = "" --we need to build a string with spaces in it
		elseif string.StartWith(word, '"') then --we need to build a string with spaces in it starting with this word, unless it ends at this word
			if string.EndsWith(word, '"') then table.insert(arguments, string.sub(word, 2, -2))
			else building = string.sub(word, 2) end
		elseif word ~= "" then  table.insert(arguments, word) end --we should add the word to the list
	end
	
	return arguments
end

--pyrition hooks
function PYRITION:PyritionConsoleComplete(prefix, arguments_string)
	local arguments = self:ConsoleParseArguments(arguments_string)
	local argument_count = #arguments
	local completions = {}
	local hint
	local tree, depth = self:ConsoleCommandGet(arguments)
	
	local command_arguments = tree.Arguments
	local prefix_arguments_string = table.concat(arguments, " ", 1, depth)
	local depth_argument = arguments[math.max(depth, 1)] or ""
	local next_argument = arguments[depth + 1] or ""
	
	if is_pyrition_command(tree) then
		local complete_function = tree.Complete
		local complete_prefix = prefix .. prefix_arguments_string
		
		if complete_function then complete_function(completions, complete_prefix, next_argument) end
		
		--ourself, may get removed depending on command argument class completions
		table.insert(completions, complete_prefix)
		
		do --other commands
			local arguments = table.Copy(arguments)
			
			if argument_count ~= depth then table.remove(arguments) end
			
			table.remove(arguments)
			
			insert_prefixed_commands(completions, tree, next_argument, complete_prefix .. " ")
			insert_prefixed_commands(completions, self:ConsoleCommandGet(arguments), depth_argument, prefix)
			
			table.remove(completions)
			table.sort(completions)
		end
		
		do --command argument class completion function
			local argument_count_excited = string.Right(arguments_string, 1) == " " and argument_count + 1 or argument_count
			local command_argument_index = math.max(argument_count_excited - depth, 1)
			local settings = command_arguments[command_argument_index]
			
			if settings then
				local class = settings.Class
				local class_argument = arguments[depth + command_argument_index] or ""
				local command_argument_object = command_argument_classes[class]
				
				if command_argument_object.Complete then
					local insertions
					
					--because hint is in a higher scope
					insertions, hint = command_argument_object:Complete(LocalPlayer(), settings, class_argument)
					
					if insertions and next(insertions) then
						--remove the blank command completion
						for index, completion in ipairs(completions) do
							if completion == complete_prefix then
								table.remove(completions, index)
								
								break
							end
						end
						
						--add our new insertions
						complete_prefix = prefix .. table.concat(arguments, " ", 1, depth + command_argument_index - 1)
						
						for index, insertion in ipairs(insertions) do table.insert(completions, complete_prefix .. (tree[insertion] and " ?" or " ") .. insertion) end
					end
				else table.insert(class) end
				
				--the hint in the chat box of what should be there
				if string.TrimLeft(class_argument) == "" then hint = hint or language.GetPhrase("pyrition.command.argument." .. string.lower(class))
				else hint = nil end
			end
		end
	elseif is_pyrition_command_organizer(tree) then
		insert_prefixed_commands(completions, tree, next_argument, prefix .. prefix_arguments_string .. " ")
		table.sort(completions)
	else
		insert_prefixed_commands(completions, tree, depth_argument, prefix .. prefix_arguments_string)
		table.sort(completions)
	end
	
	return completions, hint
end

--post
if SERVER and game.SinglePlayer() then
	create_master_command("sv_pyrition")
	create_master_command("sv_pyrition_nfr", "pyrition.command.help.nfr", true)
else
	create_master_command("pyrition")
	create_master_command("pyrition_nfr", "pyrition.command.help.nfr", true)
	
	--hee hee hee haw |\/\/|
	create_master_command("ulx", "pyrition.command.help.ulx")
end