--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching

--command argument methods
function ARGUMENT:Complete(_ply, settings, argument)
	local completions = {}
	local default = settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if default then insert_if_matching(completions, argument, tostring(default)) end
	
	if minimum and maximum then
		local maximum, minimum = tostring(maximum), tostring(minimum)
		
		insert_if_matching(completions, argument, minimum)
		insert_if_matching(completions, argument, maximum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.number.range", {maximum = maximum, minimum = minimum})
	elseif maximum then
		local maximum = tostring(maximum)
		
		insert_if_matching(completions, argument, maximum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.number.maximum", {maximum = maximum})
	elseif minimum then
		local minimum = tostring(minimum)
		
		insert_if_matching(completions, argument, minimum)
		
		return completions, PYRITION:LanguageFormat("pyrition.command.argument.number.minimum", {minimum = minimum})
	end
	
	return completions
end

function ARGUMENT:Filter(_ply, settings, argument)
	--first return should be a bool for validity of argument
	--second return should be the value itself, and is ignored if the first return is false
	--third return is a message, and is only useful if the first return is false
	local number = tonumber(argument)
	
	if not number then return end
	
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	local rounding = settings.Rounding
	
	if rounding then math.Round(number, rounding == true and 0 or rounding) end
	if maximum then number = math.min(number, maximum) end
	if minimum then number = math.max(number, minimum) end
	
	return number and true or false, number
end

function ARGUMENT:ReadSettings(stream, settings)
	local read_float = stream.ReadFloat
	
	settings.Default = stream:ReadMaybe(read_float)
	settings.Maximum = stream:ReadMaybe(read_float)
	settings.Minimum = stream:ReadMaybe(read_float)
	settings.Rounding = stream:ReadMaybe(stream.ReadUInt, 4)
end

function ARGUMENT:WriteSettings(stream, settings)
	local rounding = settings.Rounding
	local write_float = stream.WriteFloat
	
	stream:WriteMaybe(write_float, settings.Default)
	stream:WriteMaybe(write_float, settings.Maximum)
	stream:WriteMaybe(write_float, settings.Minimum)
	stream:WriteMaybe(stream.WriteUInt, rounding == true and 0 or rounding, 4)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Number", ARGUMENT)