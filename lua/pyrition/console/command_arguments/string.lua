--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching

--command argument methods
function ARGUMENT:Complete(ply, settings, argument)
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

function ARGUMENT:Filter(ply, settings, argument)
	local default = settings.Default
	
	if not argument then return default and true or false, default end
	
	local length = #argument
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if maximum and length > maximum then argument = string.Left(argument, maximum)
	elseif minimum and length < minimum then return false, nil, PYRITION:LanguageFormat("pyrition.command.argument.string.minimum", {minimum = minimum}) end
	
	return argument and true or false, argument
end

function ARGUMENT:Read(stream, settings)
	settings.Default = stream:ReadMaybe("ReadString")
	settings.Maximum = stream:ReadMaybe("ReadLong")
	settings.Minimum = stream:ReadMaybe("ReadLong")
end

function ARGUMENT:Write(stream, settings)
	stream:WriteMaybe("WriteString", settings.Default)
	stream:WriteMaybe("WriteLong", settings.Maximum)
	stream:WriteMaybe("WriteLong", settings.Minimum)
end

--post
PYRITION:ConsoleCommandRegisterArgument("String", ARGUMENT)