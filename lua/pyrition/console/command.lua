--locals
local assert = assert
local build_command_list
local commands = PYRITION.ConsoleCommands or {}
local grow_command_tree
local isstring = isstring
local is_pyrition_command = PYRITION._IsPyritionCommand
local is_pyrition_command_indexable = PYRITION._IsPyritionCommandIndexable
local is_pyrition_command_organizer = PYRITION._IsPyritionCommandOrganizer
local _R = debug.getregistry()

--local tables
local command_indexing = {
	Execute = function(self, ...) return false, self .. " is missing an Execute method override. Please report this to the developer." end,
	Initialize = function(_self, ...) return true end,
	IsPyritionCommand = true,
	MetaName = "PyritionCommand",
	OnReload = function(_self, _new_command) end,
	OnReloaded = function(_self, _old_command) end,
}

local command_meta = {
	__index = command_indexing,
	__name = "PyritionCommand"
}

--local functions
function build_command_list(commands, maximum_depth, depth, returns)
	local returns = returns or {}
	
	for key, value in pairs(commands) do
		if is_pyrition_command(value) then
			if depth >= maximum_depth then table.insert(returns, value)
			else table.insert(returns, build_command_list(value, maximum_depth, depth + 1, returns)) end
		end
	end
	
	return returns
end

local function network_execution(self) --used for server-side commands that are executable by the client
	ErrorNoHalt("ID10T-22: Attempt to execute command " .. tostring(self) .. " from client when it is only available on the server!")
	
	return true
end

function grow_command_tree(commands, maximum_depth, depth)
	local tree = {}
	
	for key, value in pairs(commands) do
		if is_pyrition_command(value) then
			if depth >= maximum_depth then tree[value.Name] = {}
			else tree[value.Name] = grow_command_tree(value, maximum_depth, depth + 1) end
		end
	end
	
	return tree
end

--globals
_R.PyritionCommand = command_meta
PYRITION.ConsoleCommands = commands

--command meta functions
function command_meta:__call(...) return self:Execute(...) end --ply, full_command, arguments...

function command_meta:__concat(alpha)
	local flip
	
	if is_pyrition_command(alpha) then self, alpha, flip = alpha, self, true end
	if isnumber(alpha) then alpha = tostring(alpha) end
	
	assert(isstring(alpha), "attempt to concatenate a PyritionCommand with a non-string (" .. type(is_pyrition_command(self) and self or alpha) .. ") value")
	
	return flip and alpha .. tostring(self) or tostring(self) .. alpha
end

function command_meta:__lt(alpha) --check if self is a parent of alpha
	--used like parent > child
	--can also be child < parent
	--general rule, is the shoter parent list should point at the longer parent list
	assert(is_pyrition_command(alpha), "attempt to check PyritionCommand nesting with " .. type(alpha) .. " value")
	
	local parents = self.Parents
	
	for index, parent in ipairs(alpha.Parents) do if parent ~= parents[index] then return false end end
	
	return true
end

function command_meta:__tostring() return "PyritionCommand [" .. table.concat(self.Parents, ".") .. "]" end

--pyrition functions
function PYRITION:ConsoleCommandGet(parents, modify, max_depth)
	if isstring(parents) then parents = string.Split(parents, " ") end
	
	local branch = commands
	local count = #parents
	local max_depth = max_depth or math.huge
	
	for index, parent in ipairs(parents) do
		local twig = branch[parent]
		
		if string.StartWith(parent, "?") then
			if modify then parents[index] = string.sub(parent, 2) end
			
			return branch, index - 1
		elseif is_pyrition_command_indexable(twig) then
			if index > max_depth then return twig, index end
			
			branch = twig
		else return branch, index - 1 end
	end
	
	return branch, count
end

function PYRITION:ConsoleCommandGetChildren(command)
	local children = {}
	
	for key, value in pairs(command) do if is_pyrition_command(value) then table.insert(children, value) end end
	
	return next(children) and children or false
end

function PYRITION:ConsoleCommandGetChildTables(command)
	local children = {}
	
	for key, value in pairs(command) do
		if is_pyrition_command(value) then table.insert(children, value)
		elseif istable(value) and string.lower(key) == key and key == value.Name then table.insert(children, value) end
	end
	
	return next(children) and children or false
end

function PYRITION:ConsoleCommandGetExisting(parents)
	if isstring(parents) then parents = string.Split(parents, " ") end
	
	local branch, count = self:ConsoleCommandGet(parents)
	
	if is_pyrition_command_organizer(branch) then return false, count end
	if count == #parents then return branch, count end
	
	return false, count
end

function PYRITION:ConsoleCommandGetList(subject) return build_command_list(subject or commands, maximum_depth, 0) end
function PYRITION:ConsoleCommandGetTree(maximum_depth) return grow_command_tree(commands, maximum_depth or 4, 0) end

function PYRITION:ConsoleCommandSend(command, arguments, ply) --run a command on the other realm
	--
	self:NetStreamModelGet("command", ply)(command, arguments)
end

--pyrition hooks
function PYRITION:PyritionConsoleCommandDownload(parents, arguments)
	local command = {
		Arguments = arguments or {Required = 0},
		Downloaded = true,
		Execute = network_execution,
		Name = parents[#parents],
		Parents = parents
	}
	
	command = table.Merge(table.Copy(command_indexing), command)
	
	setmetatable(command, command_meta)
	self:ConsoleCommandSet(parents, command)
	
	--MsgC(color_white, "Downloaded command mirror " .. command, "\n")
	
	return command
end

function PYRITION:PyritionConsoleCommandExecute(ply, command, arguments)
	local success, message, phrases = command(ply, unpack(arguments))
	
	--nil = script error
	--false = failed
	--true = success
	if success == nil then
		if message then ErrorNoHaltWithStack("ID10T-1: " .. tostring(command) .. " missing return value. Message: " .. tostring(message))
		else
			message = "Missing return value, please contact the developer of this command."
			
			ErrorNoHaltWithStack("ID10T-1: " .. tostring(command) .. " missing return value.")
		end
	end
	
	return success, message, phrases
end

function PYRITION:PyritionConsoleCommandRegister(parents, command, base_parents)
	if isstring(parents) then parents = string.Split(parents, " ")
	else parents = table.Copy(parents) end
	
	if isstring(base_parents) then base_parents = string.Split(base_parents, " ")
	else base_parents = base_parents and table.Copy(base_parents) end
	
	local base = base_parents and self:ConsoleCommandGetExisting(base_parents)
	local existing_command = self:ConsoleCommandGetExisting(parents)
	
	command.Name = parents[#parents]
	command.Parents = parents
	
	if base then
		local base_initialize = base.Initialize
		local command_initialize = command.Initialize
		
		--modifications to the table being registered
		command.BaseParents = base_parents
		command.BaseInitialize = base_initialize
		
		--merge initialize functions
		if base_initialize and command_initialize then
			command.InitializeX = command_initialize
			
			function command:Initialize(...)
				self:BaseInitialize(...)
				
				return self:InitializeX(...)
			end
		end
		
		--finally merge
		command = table.Merge(table.Copy(base), command)
	end
	
	local arguments = command.Arguments
	
	if arguments then
		if not arguments.Required then arguments.Required = 0 end
		
		for index, argument_data in ipairs(arguments) do if isstring(argument_data) then arguments[index] = {Class = argument_data} end end
	else
		command.Arguments = {Required = 0}
		
		--scream at the developer
		if arguments == nil then ErrorNoHalt("ID10T-7: Registered a command '" .. table.concat(parents, ".") .. "' without an Arguments table. Auto-completion will not be generated. To silence this error, set Arguments to false in your COMMAND table.\n") end
	end
	
	--finally set meta
	command = table.Merge(table.Copy(command_indexing), command)
	
	setmetatable(command, command_meta)
	
	if existing_command then existing_command:OnReload(command) end
	
	self:ConsoleCommandSet(parents, command)
	command:Initialize()
	
	if existing_command then
		command:OnReloaded(existing_command)
		self:ConsoleCommandReloaded(existing_command, command)
	end
	
	return command
end

function PYRITION:PyritionConsoleCommandReloaded(old_command, _new_command) MsgC(Color(255, 192, 46), "[Pyrition] Reloaded '" .. tostring(old_command) .. "'\n") end

function PYRITION:PyritionConsoleCommandSet(parents, command_table)
	local branch = commands
	local count = #parents
	
	for index, parent in ipairs(parents) do
		local twig = branch[parent]
		
		if index == count then
			local children
			
			if istable(twig) then
				children = {}
				
				--build a table of child commands and command organizers
				for name, child in pairs(twig) do if is_pyrition_command_indexable(child) and name ~= "BaseClass" then children[name] = child end end
				
				--we empty and merge to maintain the same reference
				table.Empty(twig)
				
				--we must set command_table to this reference we are trying to keep
				command_table = table.Merge(twig, command_table)
			else branch[parent] = command_table end
			
			command_table.IsPyritionCommandOrganizer = nil
			command_table.Name = parents[#parents]
			command_table.Parents = table.Copy(parents)
			
			--if we had children commands in the command we are replacing, restore them
			if children then table.Merge(command_table, children) end
			
			return command_table
		elseif istable(twig) then branch = twig
		else
			twig = {
				IsPyritionCommandOrganizer = true,
				Name = parent
			}
			
			--maintain reference
			branch[parent] = twig
			branch = twig
		end
	end
end

--post
PYRITION:GlobalHookCreate("ConsoleCommandRegister")
PYRITION:GlobalHookCreate("ConsoleCommandRegisterArgument")
PYRITION:GlobalHookCreate("ConsoleCommandReloaded")
PYRITION:GlobalHookCreate("ConsoleCommandSet")