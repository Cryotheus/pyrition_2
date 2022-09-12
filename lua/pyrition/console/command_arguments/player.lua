--locals
local ARGUMENT = {}
local insert_if_matching = PYRITION._InsertIfMatching
local max_players_bits = PYRITION.NetMaxPlayerBits
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
	local completions = {} --needle, supplicant, single, exclude_supplicant, allow_empty
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
	
	if istable(argument) then --validate a player lsit
		--don't allow invalid players
		for index, member in ipairs(argument) do if not member:IsValid() or not member:IsPlayerOrWorld() then return false end end
		
		argument.IsPlayerList = true
		
		return true, argument
	end
	
	if IsEntity(argument) then --validate a player entity
		--valid player, and is player entity
		if argument:IsValid() and argument:IsPlayerOrWorld() then return true, argument end
		
		return false
	end
	
	if isstring(argument) then --otherwise, find a player
		--RELEASE: prevent this from being used as an exploit
		--if a player has a different name than what the client sees
		--a player could override this to only send a string and find the player by that original name
		--otherwise
		local find, message
		
		if settings.Default and not argument or argument == "" then find, message = PYRITION:PlayerFindWithFallback(argument, ply, ply, settings.Single, settings.Selfless)
		else find, message = PYRITION:PyritionPlayerFind(argument, ply, settings.Single, settings.Selfless) end
		
		return find and true or false, find, message
	end
	
	return false
end

function ARGUMENT:Read(stream, settings)
	if settings.Manual then return stream:ReadString() end
	if settings.Single then return stream:ReadPlayer(argument) end
	
	return stream:ReadList(max_players_bits, stream.ReadPlayer)
end

function ARGUMENT:ReadSettings(stream, settings)
	if stream:ReadBool() then
		settings.Manual = true
		
		return
	end
	
	settings.Default = stream:ReadBool()
	settings.Selfless = stream:ReadBool()
	settings.Single = stream:ReadBool()
end

function ARGUMENT:Write(stream, settings, argument)
	if settings.Manual then return stream:WriteString(argument) end
	if settings.Single then return stream:WritePlayer(argument) end
	
	stream:WriteList(argument, max_players_bits, stream.WritePlayer)
end

function ARGUMENT:WriteSettings(stream, settings)
	if settings.Manual then return self:WriteBool(true) end
	
	stream:WriteBool(false)
	stream:WriteBool(settings.Default)
	stream:WriteBool(settings.Selfless)
	stream:WriteBool(settings.Single)
end

--post
PYRITION:ConsoleCommandRegisterArgument("Player", ARGUMENT)