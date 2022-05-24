--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses or {}
local is_pyrition_command

--local functions
local function command_callback(ply, command, arguments)
	local arguments_count = #arguments
	local command, depth = PYRITION:ConsoleCommandGet(arguments, true)
	
	if depth == 0 then PYRITION:LanguageQueue(ply, "pyrition.command.unknown")
	else
		local subbed_arguments = {}
		
		for index = depth + 1, arguments_count do table.insert(subbed_arguments, arguments[index]) end
		
		PYRITION:ConsoleExecute(ply, command, subbed_arguments)
	end
end

local function command_localization(command) return "#pyrition.commands." .. table.concat(command.Parents, ".") end

local function insert_prefixed_commands(completions, tree, validation_prefix, command_prefix)
	for name, command in pairs(tree) do
		if string.StartWith(name, validation_prefix) and is_pyrition_command(command) then
			table.insert(completions, command_prefix .. name)
		end
	end
end

function is_pyrition_command(object) return istable(object) and object.IsPyritionCommand or false end

--globals
PYRITION.ConsoleCommandArgumentClasses = command_argument_classes
PYRITION._IsPyritionCommand = is_pyrition_command

--pyrition functions
function PYRITION:ConsoleExecute(ply, command, arguments)
	local command_arguments = command.Arguments or {}
	local required = command_arguments.Required or 0
	
	if not IsValid(ply) then ply = game.GetWorld() end
	
	if ply == game.GetWorld() and not command.Console then
		--we shouldn't let the console run commands that are not marked as console safe
		return PYRITION:LanguageQueue(ply, "pyrition.command.failed.console", {command = command_localization(command)})
	end
	
	if #arguments < required then
		if required == 1 then PYRITION:LanguageQueue(ply, "pyrition.command.failed.required_arguments.singular", {command = command_localization(command)})
		else PYRITION:LanguageQueue(ply, "pyrition.command.failed.required_arguments", {command = command_localization(command), count = required}) end
		
		return false
	end
	
	local success, message, phrases = PYRITION:ConsoleCommandExecute(ply, command, unpack(arguments))
		
	if message then PYRITION:LanguageQueue(success or ply, message, table.Merge({executor = ply}, phrases or {}))
	elseif success then
		if not command.Downloaded then
			--we don't send a message for downloaded commands
			PYRITION:LanguageQueue(ply, "pyrition.command.success", {command = command_localization(command)})
		end
	else PYRITION:LanguageQueue(ply, "pyrition.command.failed", {command = command_localization(command)}) end
	
	return success
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
				local completion_function = command_argument_classes[class][2]
				
				if completion_function then
					local insertions = completion_function(settings, LocalPlayer(), arguments[depth + command_argument_index] or "")
					
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
						
						for index, insertion in ipairs(insertions) do table.insert(completions, complete_prefix .. " " .. insertion) end
					end
				else table.insert(class) end
			end
		end
	else
		insert_prefixed_commands(completions, tree, depth_argument, prefix .. prefix_arguments_string)
		table.sort(completions)
	end
	
	return completions
end

--console commands
concommand.Add(
	SERVER and game.SinglePlayer() and sv_pyrition or "pyrition",
	command_callback,
	
	function(command, arguments_string)
		--yeah that's right, autocomplete on console ⌐■_■
		--only useful for singleplayer or custom srcds consoles
		return PYRITION:ConsoleComplete(command .. " ", arguments_string)
	end,
	
	language.GetPhrase("pyrition.command.help")
)
