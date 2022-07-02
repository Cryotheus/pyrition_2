--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching
local parse_time = PYRITION._TimeParse
local shorthand_time = PYRITION._TimeShorthand
local time_thresholds = PYRITION.TimeThresholds
local time_units = PYRITION.TimeUnits

--command argument methods
function ARGUMENT:Complete(_ply, settings, argument)
	local completions = {}
	local default = settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	local unit = time_units[time_thresholds[settings.Unit] or 1]
	
	if default then insert_if_matching(completions, argument, shorthand_time(default)) end
	
	if minimum and maximum then
		local maximum, minimum = shorthand_time(maximum), shorthand_time(minimum)
		
		insert_if_matching(completions, argument, minimum)
		insert_if_matching(completions, argument, maximum)
		
		return completions, unit .. "   " .. PYRITION:LanguageFormat("pyrition.command.argument.time.range", {maximum = maximum, minimum = minimum})
	elseif maximum then
		local maximum = shorthand_time(maximum)
		
		insert_if_matching(completions, argument, maximum)
		
		return completions, unit .. "   " .. PYRITION:LanguageFormat("pyrition.command.argument.time.maximum", {maximum = maximum})
	elseif minimum then
		local minimum = shorthand_time(minimum)
		
		insert_if_matching(completions, argument, minimum)
		
		return completions, unit .. "   " .. PYRITION:LanguageFormat("pyrition.command.argument.time.minimum", {minimum = minimum})
	end
	
	return completions
end

function ARGUMENT:Filter(_ply, settings, argument)
	local time = parse_time(argument)
	
	if not time then return false end
	
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	--no inf with time, ok?
	if math.abs(time) == math.huge then return false, nil end
	if maximum then time = math.min(time, maximum) end
	if minimum then time = math.max(time, minimum) end
	
	return time and true or false, time
end

function ARGUMENT:ReadSettings(stream, settings)
	local read_long = stream.ReadULong
	
	settings.Default = stream:ReadMaybe(read_long)
	settings.Maximum = stream:ReadMaybe(read_long)
	settings.Minimum = stream:ReadMaybe(read_long)
	settings.Unit = stream:ReadMaybe(stream.ReadUInt, 3)
end

function ARGUMENT:WriteSettings(stream, settings)
	local write_long = stream.WriteULong
	local unit = settings.Unit
	
	stream:WriteMaybe(write_long, settings.Default)
	stream:WriteMaybe(write_long, settings.Maximum)
	stream:WriteMaybe(write_long, settings.Minimum)
	
	for index, threshold in ipairs(time_thresholds) do
		--find the unit we are using, and write it by its index
		if unit == threshold then return stream:WriteMaybe(stream.WriteUInt, index, 3) end
	end
	
	--if we did not find the threshold, write the WriteMaybe's bool
	stream:WriteBool(false)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Time", ARGUMENT)