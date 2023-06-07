local ARGUMENT = {
	ParseSettingMacros = {
		Default = "Present",
		Selfless = "Present",
		Single = "Present",
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
	GetDefault
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

	return completions, language.GetPhrase(self.Single and "pyrition.command.argument.player" or "pyrition.command.argument.players")
end

function ARGUMENT:Filter(_executor, argument)
	--should return a value for if the filter passed
	--and a second value of the filtered result
	--eg. we convert ` : string -> success: boolean, player: Player`

	return false
end

function ARGUMENT:Read(stream) --called when we are reading a command argument from a stream
	if self.Single then return stream:ReadPlayer(argument) end

	return stream:ReadList(max_players_bits, stream.ReadPlayer)
end

function ARGUMENT:ReadSettings(stream) --called when we are reading a settings table from a stream
	self.Default = stream:ReadBool()
	self.Selfless = stream:ReadBool()
	self.Single = stream:ReadBool()
end

function ARGUMENT:Write(stream, argument) --called when we are writing a command argument to a stream
	if self.Single then return stream:WritePlayer(argument) end

	stream:WriteList(argument, max_players_bits, stream.WritePlayer)
end

function ARGUMENT:WriteSettings(stream) --called when we are writing a settings table to a stream
	stream:WriteBool(self.Default)
	stream:WriteBool(self.Selfless)
	stream:WriteBool(self.Single)
end

PYRITION:CommandArgumentRegister("Player", ARGUMENT)