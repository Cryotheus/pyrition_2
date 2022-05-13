--locals
local is_pyrition_command = PYRITION._IsPyritionCommand

--local functions
local function insert_prefixed_commands(completions, tree, validation_prefix, command_prefix)
	for name, command in pairs(tree) do
		if string.StartWith(name, validation_prefix) and is_pyrition_command(command) then
			table.insert(completions, command_prefix .. name)
		end
	end
end

--pyrition hooks
function PYRITION:PyritionConsoleComplete(prefix, arguments_string)
	local arguments = self:ConsoleParseArguments(arguments_string)
	local argument_count = #arguments
	local completions = {}
	local tree, depth = self:ConsoleCommandGet(arguments)
	
	local prefix_arguments_string = table.concat(arguments, " ", 1, depth)
	local depth_argument = arguments[math.max(depth, 1)] or ""
	local next_argument = arguments[depth + 1] or ""
	
	if is_pyrition_command(tree) then
		local complete_function = tree.Complete
		local complete_prefix = prefix .. " " .. prefix_arguments_string
		
		if complete_function then complete_function(completions, complete_prefix, next_argument) end
		
		table.insert(completions, complete_prefix)
		
		--add child commands
		--for name, command in pairs(tree) do
		--	if string.StartWith(name, next_argument) and is_pyrition_command(command) then
		--		table.insert(completions, complete_prefix .. " " .. name)
		--	end
		--end
		
		if argument_count ~= depth then table.remove(arguments) end
		
		table.remove(arguments)
		
		insert_prefixed_commands(completions, tree, next_argument, complete_prefix .. " ")
		insert_prefixed_commands(completions, self:ConsoleCommandGet(arguments), depth_argument, prefix .. " ")
		
		table.remove(completions)
	else insert_prefixed_commands(completions, tree, depth_argument, prefix .. " " .. prefix_arguments_string) end
	
	--add commands
	
	
	return completions
end