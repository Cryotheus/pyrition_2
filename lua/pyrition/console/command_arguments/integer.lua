--locals
local ARGUMENT = {}
local bits = PYRITION._Bits
local insert_if_matching = PYRITION._InsertIfMatching
local long_maximum = 2 ^ 31 - 1
local long_minimum = -1 - long_maximum

--command argument methods
function ARGUMENT:Complete(_ply, settings, argument)
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

function ARGUMENT:Filter(_ply, settings, argument)
	--first return should be a bool for validity of argument
	--second return should be the value itself, and is ignored if the first return is false
	--third return is a message, and is only useful if the first return is false
	local integer = tonumber(argument)
	
	if not integer then return false end
	if not settings.Signed and integer < 0 then return false end
	
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	--no inf with integers, ok?
	if math.abs(integer) == math.huge then return false end
	if maximum then integer = math.min(integer, maximum) end
	if minimum then integer = math.max(integer, minimum) end
	
	return integer and true or false, integer
end

function ARGUMENT:Read(stream, settings)
	local maximum = settings.Maximum or long_maximum
	local minimum = settings.Minimum or settings.Signed and 0 or long_minimum
	
	return stream:ReadUInt(bits(maximum - minimum + 1)) - minimum
end

function ARGUMENT:ReadSettings(stream, settings)
	local signed = stream:ReadBool()
	local read_long = signed and stream.ReadLong or stream.ReadULong
	
	settings.Signed = signed
	settings.Default = stream:ReadMaybe(read_long)
	settings.Maximum = stream:ReadMaybe(read_long)
	settings.Minimum = stream:ReadMaybe(read_long)
end

function ARGUMENT:Write(stream, settings, argument)
	local maximum = settings.Maximum or long_maximum
	local minimum = settings.Minimum or settings.Signed and 0 or long_minimum
	
	stream:WriteUInt(argument + minimum, bits(maximum - minimum + 1))
end

function ARGUMENT:WriteSettings(stream, settings)
	local signed = settings.Signed
	local write_long = signed and stream.WriteLong or stream.WriteULong
	
	stream:WriteBool(signed)
	stream:WriteMaybe(write_long, settings.Default)
	stream:WriteMaybe(write_long, settings.Maximum)
	stream:WriteMaybe(write_long, settings.Minimum)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Integer", ARGUMENT)