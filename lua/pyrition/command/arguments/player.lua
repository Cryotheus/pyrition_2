local ARGUMENT = {
	ParseSettingMacros = {
		Selfless = "Present", --disallow targetting the executor
		Single = "Present", --limit targetting to a single player
		TargetConsole = "Present", --allow targetting console
	},
}

local function insert_if_matching(completions, argument, insertion, position)
	if string.StartWith(insertion, argument) then
		if position then return table.insert(completions, position, insertion) end

		return table.insert(completions, insertion)
	end
end

--[[
	Complete - return a list of strings for possible completions
	Filter - turns a string into a success bool and a value of the appropriate type
	Read
	ReadSettings
	Write
	WriteSettings
]]

function ARGUMENT:Complete(executor, argument)
	local argument = string.lower(argument)
	local completions = {} --needle, supplicant, single, exclude_supplicant, allow_empty
	local targets = PYRITION:PlayerFind(argument, executor, false, self.Selfless, true)

	if targets then
		if IsEntity(targets) then table.insert(completions, tostring(targets))
		else
			for index, target in ipairs(targets) do table.insert(completions, escape_targetting(target)) end

			table.sort(completions)
		end
	end

	if argument == "" or not targets then
		if not self.Selfless then insert_if_matching(completions, argument, "^", 1) end

		if not self.Single then
			insert_if_matching(completions, argument, "*")
			insert_if_matching(completions, argument, "^^")
			insert_if_matching(completions, argument, "%")
		end

		if not executor:IsWorld() then
			local steam_id = executor:SteamID()

			insert_if_matching(completions, argument, "#" .. executor:UserID())
			insert_if_matching(completions, argument, "$" .. steam_id)
			insert_if_matching(completions, argument, "$" .. string.sub(steam_id, 9))
		end
	end

	return completions
end

function ARGUMENT:Filter(executor, argument)
	--should return a value for if the filter passed
	--and a second value of the filtered result
	--eg. we convert ` : string -> success: boolean, player: Player`

	if istable(argument) then --validate a player lsit
		--don't allow invalid players
		if self.TargetConsole then for index, member in ipairs(argument) do if not member:IsValid() or not member:IsPlayerOrWorld() then return false end end
		else for index, member in ipairs(argument) do if not member:IsValid() or not member:IsPlayer() then return false end end end

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
		local find, message = PYRITION:PlayerFind(argument, executor, self.Single, self.Selfless)

		return find and true, find, message
	end

	return false
end

function ARGUMENT:Read(stream) --called when we are reading a command argument from a stream
	if self.Single then return stream:ReadPlayer(argument) end

	return stream:ReadList(max_players_bits, stream.ReadPlayer)
end

function ARGUMENT:ReadSettings(stream) --called when we are reading a settings table from a stream
	self.Selfless = stream:ReadBool()
	self.Single = stream:ReadBool()
	self.TargetConsole = stream:ReadBool()
end

function ARGUMENT:Write(stream, argument) --called when we are writing a command argument to a stream
	if self.Single then return stream:WritePlayer(argument) end

	stream:WriteList(argument, max_players_bits, stream.WritePlayer)
end

function ARGUMENT:WriteSettings(stream) --called when we are writing a settings table to a stream
	stream:WriteBool(self.Selfless or false)
	stream:WriteBool(self.Single or false)
	stream:WriteBool(self.TargetConsole or false)
end

PYRITION:CommandArgumentRegister("Player", ARGUMENT)
