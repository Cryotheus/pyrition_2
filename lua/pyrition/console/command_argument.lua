--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses
local _R = debug.getregistry()

--local tables
local argument_meta = {}
local argument_public = {__index = stream_meta, __name = "PyritionCommandArgument"}

--local functions
local function insert_if_matching(completions, argument, insertion, position)
	if string.StartWith(insertion, argument) then
		if position then return table.insert(completions, position, insertion) end
			
		return table.insert(completions, insertion)
	end
end

--globals
PYRITION._InsertIfMatching = insert_if_matching
_R.PyritionStream = stream_public

--meta functions
function argument_public:__call(...) return self:Filter(...) end
function argument_public:__tostring() return "PyritionCommandArgument [" .. self.Class .. "]" end
function argument_meta:Filter(ply, settings, argument) ErrorNoHalt("ID10T-19: Object " .. tostring(self) .. " is missing Filter method.") end

--pyrition functions
function PYRITION:ConsoleCommandArgumentFilter(ply, settings, argument)
	local class = settings.Class
	local command_argument = command_argument_classes[class]
	
	assert(command_argument, "ID10T-11: Attempt to filter command argument with non-existent command argument class " .. tostring(class) .. ".")
	
	return command_argument(settings, ply, argument)
end

function PYRITION:ConsoleCommandArgumentValidate(ply, command, arguments)
	--basically, fail the execution if a required argument is invalid
	--and ignore optional arguments that are invalid
	--if we have an argument marked with Optional and it is invalid, pop it
	local argument_count = #arguments
	local command_arguments = command.Arguments
	local index = 1
	local required = command_arguments.Required
	
	--I can't adjust the index ipairs is on so I'm using a while loop
	while index <= argument_count do
		local command_argument = command_arguments[index]
		local valid, value, message = self:ConsoleCommandArgumentFilter(ply, command_argument, arguments[index])
		
		if valid then
			arguments[index] = value
			index = index + 1
		else
			if command_argument.Optional then
				arguments[index] = nil
				
				if index <= required then required = required + 1 end
			else
				if index <= required then return false, index, message
				else arguments[index] = nil end
			end
			
			index = index + 1
		end
	end
	
	return true
end

--pyrition hooks
function PYRITION:PyritionConsoleCommandRegisterArgument(class, argument_table, base_class)
	assert(isstring(class) and istable(argument_table) and (isstring(base_class) or not base_class), "ID10T-10: Argument mismatch in registering command arguments.")
	
	local base = base_class and command_argument_classes[base_class]
	argument_table.Class = class
	
	if base then --inherit base's fields
		argument_table.BaseClass = base_class
		argument_table = table.Merge(table.Copy(base), argument_table)
	end
	
	local read_function, write_function = argument_table.Read, argument_table.Write
	
	assert(read_function and write_function or not (read_function or write_function), "ID10T-13: Either both network functions or no network functions are required.")
	
	if SERVER then self:NetAddEnumeratedString("command_argument", class) end
	
	command_argument_classes[class] = setmetatable(argument_table, argument_public)
end

--post
PYRITION:GlobalHookCreate("ConsoleCommandRegisterArgument")