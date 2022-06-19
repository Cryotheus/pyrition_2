--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching

--command argument methods
function ARGUMENT:Complete(ply, settings, argument)
	--return should be a list of strings for the command's completion
	local completions = {}
	local default = settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if default then insert_if_matching(completions, argument, tostring(default)) end
	
	if minimum and maximum then
		local maximum, minimum = tostring(maximum), tostring(minimum)
		
		insert_if_matching(completions, argument, minimum)
		insert_if_matching(completions, argument, maximum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.integer.range", {maximum = maximum, minimum = minimum})
	elseif maximum then
		local maximum = tostring(maximum)
		
		insert_if_matching(completions, argument, maximum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.integer.maximum", {maximum = maximum})
	elseif minimum then
		local minimum = tostring(minimum)
		
		insert_if_matching(completions, argument, minimum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.integer.minimum", {minimum = minimum})
	end
	
	return completions
end

function ARGUMENT:Filter(ply, settings, argument)
	--first return should be a bool for validity of argument
	--second return should be the value itself, and is ignored if the first return is false
	--third return is a message, and is only useful if the first return is false
	local integer = tonumber(argument)
	
	if not integer then return false end
	
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	--no inf with integers, ok?
	if math.abs(integer) == math.huge then return false end
	if maximum then integer = math.min(integer, maximum) end
	if minimum then integer = math.max(integer, minimum) end
	
	return integer and true or false, integer
end

function ARGUMENT:Read(stream, settings)
	local signed = stream:ReadBool()
	local key = signed and "ReadLong" or "ReadULong"
	
	settings.Signed = signed
	settings.Default = stream:ReadMaybe(key)
	settings.Maximum = stream:ReadMaybe(key)
	settings.Minimum = stream:ReadMaybe(key)
end

function ARGUMENT:Write(stream, settings)
	local signed = settings.Signed
	local key = signed and "WriteLong" or "WriteULong"
	
	stream:WriteBool(signed)
	stream:WriteMaybe(key, settings.Default)
	stream:WriteMaybe(key, settings.Maximum)
	stream:WriteMaybe(key, settings.Minimum)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Integer", ARGUMENT)