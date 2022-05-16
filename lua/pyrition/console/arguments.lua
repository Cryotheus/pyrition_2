local maybe_read = PYRITION._MaybeRead
local maybe_write = PYRITION._MaybeWrite

--post
PYRITION:ConsoleCommandRegisterArgument("Integer", function(settings, ply, argument)
	local default = settings.Default
	local integer = tonumber(argument) or default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	--no inf with integers, ok?
	if math.abs(integer) == math.huge then integer = default end
	if maximum then integer = math.min(integer, maximum) end
	if minimum then integer = math.max(integer, minimum) end
	
	return integer and true or false, integer
end, function(settings, ply, argument)
	local completions = {}
	local default = settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if default then table.insert(completions, tostring(default)) end
	if minimum then table.insert(completions, tostring(minimum)) end
	if maximum then table.insert(completions, tostring(maximum)) end
	
	return completions
end, function(settings)
	maybe_write(net.WriteUInt, settings.Default, 32)
	maybe_write(net.WriteUInt, settings.Maximum, 32)
	maybe_write(net.WriteUInt, settings.Minimum, 32)
end, function(settings)
	settings.Default = maybe_read(net.ReadUInt, 32)
	settings.Maximum = maybe_read(net.ReadUInt, 32)
	settings.Minimum = maybe_read(net.ReadUInt, 32)
end)

PYRITION:ConsoleCommandRegisterArgument("Number", function(settings, ply, argument)
	local number = tonumber(argument) or settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	local rounding = settings.Rounding
	
	if rounding then math.Round(number, isnumber(rounding) or 0) end
	if maximum then number = math.min(number, maximum) end
	if minimum then number = math.max(number, minimum) end
	
	return number and true or false, number
end, function(settings, ply, argument)
	local completions = {}
	local default = settings.Default
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if default then table.insert(completions, tostring(default)) end
	if minimum then table.insert(completions, tostring(minimum)) end
	if maximum then table.insert(completions, tostring(maximum)) end
	
	return completions
end, function(settings)
	maybe_write(net.WriteUInt, settings.Default, 32)
	maybe_write(net.WriteUInt, settings.Maximum, 32)
	maybe_write(net.WriteUInt, settings.Minimum, 32)
	maybe_write(net.WriteBool, settings.Rounding)
end, function(settings)
	settings.Default = maybe_read(net.ReadUInt, 32)
	settings.Maximum = maybe_read(net.ReadUInt, 32)
	settings.Minimum = maybe_read(net.ReadUInt, 32)
	settings.Rounding = maybe_read(net.ReadBool)
end)

PYRITION:ConsoleCommandRegisterArgument("Player", function(settings, ply, targetting)
	if settings.Manual then return true, targetting end
	
	local find, message
	
	if settings.Default and not targetting or targetting == "" then find, message = PYRITION:PlayerFindWithFallback(targetting, ply, ply, settings.Single, settings.Selfless)
	else find, message = PYRITION:PyritionPlayerFind(targetting, ply, settings.Single, settings.Selfless) end
	
	return find and true or false, find, message
end, function(settings, executor, argument)
	local completions = {}
	
	for index, ply in ipairs(player.GetAll()) do
		if ply ~= executor then
			local name = ply:Name()
			
			if string.StartWith(name, argument) then table.insert(completions, name) end
		end
	end
	
	table.sort(completions)
	
	if not settings.Selfless then table.insert(completions, 1, "^") end
	
	if not settings.Single then
		table.insert(completions, "*")
		table.insert(completions, "^^")
		table.insert(completions, "%")
	end
	
	local steam_id = executor:SteamID()
	
	table.insert(completions, "#" .. executor:UserID())
	table.insert(completions, "$" .. steam_id)
	table.insert(completions, "$" .. string.sub(steam_id, 9))
	
	return completions
end, function(settings)
	if settings.Manual then return net.WriteBool(true) end
	
	net.WriteBool(false)
	maybe_write(net.WriteBool, settings.Default)
	maybe_write(net.WriteBool, settings.Selfless)
	maybe_write(net.WriteBool, settings.Single)
end, function(settings)
	if net.ReadBool() then
		settings.Manual = true
		
		return
	end
	
	settings.Default = maybe_read(net.ReadBool)
	settings.Selfless = maybe_read(net.ReadBool)
	settings.Single = maybe_read(net.ReadBool)
end)

PYRITION:ConsoleCommandRegisterArgument("String", function(settings, ply, argument)
	local default = settings.Default
	
	if not argument then return default and true or false, default end
	
	local length = #argument
	local maximum = settings.Maximum
	local minimum = settings.Minimum
	
	if maximum and length > maximum then string.Left(argument, maximum)
	elseif minimum and length < minimum or argument == "" then argument = default end
	
	return argument and true or false, argument
end, function(settings, ply, argument)
	local default = settings.Default
	
	if default then return {default} end
	
	return {}
end, function(settings)
	maybe_write(net.WriteString, settings.Default)
	maybe_write(net.WriteUInt, settings.Maximum, 32)
	maybe_write(net.WriteUInt, settings.Minimum, 32)
end, function(settings)
	settings.Default = maybe_read(net.ReadString)
	settings.Maximum = maybe_read(net.ReadUInt, 32)
	settings.Minimum = maybe_read(net.ReadUInt, 32)
end)