--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching
local prefix_functions = PYRITION.PlayerFindPrefixes

--local functions
local function escape_targetting(target)
	local name = target:Name()
			
	if prefix_functions[string.Left(name, 1)] then return "$" .. string.sub(name:SteamID(), 9)
	else return string.find(name, "%s") and '"' .. name .. '"' or name end
end

--command argument methods
function ARGUMENT:Complete(ply, settings, argument)
	local argument = string.lower(argument)
	local completions = {}
	local targets = PYRITION:PlayerFind(argument, ply, false, settings.Selfless, true)
	
	if targets then
		if IsEntity(targets) then table.insert(completions, tostring(targets))
		else
			for index, target in ipairs(targets) do table.insert(completions, escape_targetting(target)) end
			
			table.sort(completions)
		end
	end
	
	if argument == "" or not targets then
		if not settings.Selfless then insert_if_matching(completions, argument, "^", 1) end
		
		if not settings.Single then
			insert_if_matching(completions, argument, "*")
			insert_if_matching(completions, argument, "^^")
			insert_if_matching(completions, argument, "%")
		end
		
		local steam_id = ply:SteamID()
		
		insert_if_matching(completions, argument, "#" .. ply:UserID())
		insert_if_matching(completions, argument, "$" .. steam_id)
		insert_if_matching(completions, argument, "$" .. string.sub(steam_id, 9))
	end
	
	return completions, language.GetPhrase(settings.Single and "pyrition.command.argument.player" or "pyrition.command.argument.players")
end

function ARGUMENT:Filter(ply, settings, argument)
	if settings.Manual then return true, argument end
	
	local find, message
	
	print("yuh bruh", ply, settings, argument)
	
	if settings.Default and not argument or argument == "" then find, message = PYRITION:PlayerFindWithFallback(argument, ply, ply, settings.Single, settings.Selfless)
	else find, message = PYRITION:PyritionPlayerFind(argument, ply, settings.Single, settings.Selfless) end
	
	return find and true or false, find, message
end

function ARGUMENT:Read(stream, settings)
	if stream:ReadBool() then
		settings.Manual = true
		
		return
	end
	
	settings.Default = stream:ReadMaybe("ReadBool")
	settings.Selfless = stream:ReadMaybe("ReadBool")
	settings.Single = stream:ReadMaybe("ReadBool")
end

function ARGUMENT:Write(stream, settings)
	if settings.Manual then return self:WriteBool(true) end
	
	stream:WriteBool(false)
	stream:WriteMaybe("WriteBool", settings.Default)
	stream:WriteMaybe("WriteBool", settings.Selfless)
	stream:WriteMaybe("WriteBool", settings.Single)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Player", ARGUMENT)