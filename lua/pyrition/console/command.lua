--locals
local build_command_list
local commands = PYRITION.ConsoleCommands or {}
local grow_command_tree
local is_pyrition_command
local _R = debug.getregistry()

--local tables
local command_indexing = {
	Execute = function(self, ...) return false, self .. " is missing an Execute method override. Please report this to the developer." end,
	Initialize = function(self, ...) return true end,
	IsPyritionCommand = true,
	MetaName = "PyritionCommand",
	OnReload = function(self, new_command) end,
	OnReloaded = function(self, old_command) end,
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

local function network_execution(self, ply, ...)
	net.Start("pyrition_command")
	
	do --command namespace
		local passed = false
		
		for index, parent in ipairs(self.Parents) do
			if passed then net.WriteBool(true)
			else passed = true end
			
			PYITION:NetWriteEnumeratedString("command", parent)
		end
		
		net.WriteBool(false)
	end
	
	do --command arguments
		local passed = false
		
		for index, argument in ipairs({...}) do
			if passed then net.WriteBool(true)
			else passed = true end
			
			net.WriteString(argument)
		end
		
		net.WriteBool(false)
	end
	
	net.SendToServer()
end

function grow_command_tree(commands, maximum_depth, depth)
	local tree = {}
	
	for key, value in pairs(commands) do
		if is_pyrition_command(value) and key ~= "BaseClass" then
			if depth >= maximum_depth then tree[value.Name] = {}
			else tree[value.Name] = grow_command_tree(value, maximum_depth, depth + 1) end
		end
	end
	
	return tree
end

function is_pyrition_command(object) return istable(object) and object.IsPyritionCommand or false end

--globals
_R.PyritionCommand = command_meta
PYRITION.ConsoleCommands = commands
PYRITION._IsPyritionCommand = is_pyrition_command

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
function PYRITION:ConsoleCommandGet(parents, modify)
	if isstring(parents) then parents = {parents} end
	
	local branch = commands
	local count = #parents
	
	--goto nearest
	--goto = {nearest = comm}
	
	--goto ?nearest
	--goto = comm
	
	for index, parent in ipairs(parents) do
		local twig = branch[parent]
		
		if string.StartWith(parent, "?") then
			if modify then parents[index] = string.sub(parent, 2) end
			
			return branch, index - 1
		elseif is_pyrition_command(twig) then branch = twig
		else return branch, index - 1 end
	end
	
	return branch, count
end

function PYRITION:ConsoleCommandGetExisting(parents)
	local branch, count = self:ConsoleCommandGet(parents)
	
	if count == #parents then return branch end
	
	return false
end

function PYRITION:ConsoleCommandGetList(subject) return build_command_list(subject or commands, maximum_depth, 0) end
function PYRITION:ConsoleCommandGetTree(maximum_depth) return grow_command_tree(commands, maximum_depth or 4, 0) end

--pyrition hooks
function PYRITION:PyritionConsoleCommandDownload(parents)
	local existing = self:ConsoleCommandGetExisting(parents)
	
	if existing then return existing end
	
	local command = {
		Downloaded = true,
		Execute = network_execution,
		Name = parents[#parents],
		Parents = parents
	}
	
	table.Inherit(command, command_indexing)
	setmetatable(command, command_meta)
	MsgC(color_white, "Downloaded command mirror " .. command, "\n")
	
	self:ConsoleCommandSet(parents, command)
	
	return command
end

function PYRITION:PyritionConsoleCommandExecute(ply, command, ...)
	local success, message, phrases = command(ply, ...)
	
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
	
	if CLIENT then
		local mods = {}
		
		--convert tables into strings
		for tag, phrase in pairs(phrases) do if istable(phrase) then phrases[tag] = self:LanguageList(phrase) end end
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
	
	--finally set meta
	table.Inherit(command, command_indexing)
	setmetatable(command, command_meta)
	
	if existing_command then existing_command:OnReload(command) end
	
	self:ConsoleCommandSet(parents, command)
	command:Initialize()
	
	print("register?")
	
	if existing_command then
		command:OnReloaded(existing_command)
		self:ConsoleCommandReloaded(existing_command, command)
		
		print("reload", command)
	end
	
	return command
end

function PYRITION:PyritionConsoleCommandReloaded(old_command, new_command) MsgC(Color(255, 192, 46), '[Pyrition] Reloaded "' .. old_command .. '"\n') end

function PYRITION:PyritionConsoleCommandSet(parents, command_table)
	local branch = commands
	local count = #parents
	
	for index, parent in ipairs(parents) do
		local twig = branch[parent]
		
		if index == count then
			local children
			
			if is_pyrition_command(twig) then
				children = {}
				
				for key, child in pairs(twig) do
					if is_pyrition_command(value) then
						print("child command", child)
						table.insert(children, child)
					end
				end
			end
			
			branch[parent] = command_table
			command_table.Name = parents[#parents]
			command_table.Parents = table.Copy(parents)
			
			if children then
				for index, child in ipairs(children) do
					print("restoring", child.Name, child)
					command_table[child.Name] = child
				end
			end
			
			return command_table
		elseif is_pyrition_command(twig) then branch = twig
		else
			twig = {}
			
			--maintain reference
			branch[parent] = twig
			branch = twig
		end
	end
end

--post
PYRITION:GlobalHookCreate("ConsoleCommandRegister")
PYRITION:GlobalHookCreate("ConsoleCommandReloaded")
PYRITION:GlobalHookCreate("ConsoleCommandSet")