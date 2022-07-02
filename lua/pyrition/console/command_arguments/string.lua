--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching
local replace_unsafe = PYRITION._StringReplaceUnsafe

--command argument methods
function ARGUMENT:Complete(_ply, settings, argument)
	local completions = {}
	local default = settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if default then insert_if_matching(completions, argument, default) end
	
	if minimum and maximum then
		local maximum, minimum = tostring(maximum), tostring(minimum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.string.range", {maximum = maximum, minimum = minimum})
	elseif maximum then
		local maximum = tostring(maximum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.string.maximum", {maximum = maximum})
	elseif minimum then
		local minimum = tostring(minimum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.string.minimum", {minimum = minimum})
	end
	
	return completions
end

function ARGUMENT:Filter(_ply, settings, argument)
	local default = settings.Default
	
	if not argument then return default and true or false, default end
	
	local length = #argument
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if maximum and length > maximum then argument = string.Left(argument, maximum)
	elseif minimum and length < minimum then return false, nil, PYRITION:LanguageFormat("pyrition.command.argument.string.minimum", {minimum = minimum}) end
	
	if argument then return true, settings.Safe and replace_unsafe(argument) or argument end
	
	return argument and true or false, argument
end

function ARGUMENT:ReadSettings(stream, settings)
	settings.Safe = stream:ReadBool()
	settings.Default = stream:ReadMaybe(stream.ReadString)
	settings.Maximum = stream:ReadMaybe(stream.ReadULong)
	settings.Minimum = stream:ReadMaybe(stream.ReadULong)
end

function ARGUMENT:WriteSettings(stream, settings)
	stream:WriteBool(settings.Safe)
	stream:WriteMaybe(stream.WriteString, settings.Default)
	stream:WriteMaybe(stream.WriteULong, settings.Maximum)
	stream:WriteMaybe(stream.WriteULong, settings.Minimum)
end

--post
PYRITION:ConsoleCommandRegisterArgument("String", ARGUMENT)