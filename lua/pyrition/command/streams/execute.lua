local MODEL = {Priority = 30}

function MODEL:Read(ply)
	print("Read", ply)

	local command_tables = PYRITION.CommandRegistry

	while self:ReadBool() do
		local arguments = {}
		local command_signature = self:ReadEnumeratedString("PyritionCommandSignature")
		local command_table = command_tables[command_signature]

		--this will drop all other queued commands
		--but that's fine because only hackers should trigger this
		if not command_table then return end

		for index, argument_settings in ipairs(command_table.Arguments) do
			if argument_settings.Read then arguments[index] = argument_settings:Read(self) end
		end

		PYRITION:CommandExecute(command_signature, arguments, ply)
	end
end

function MODEL:Write(command_signature, arguments)
	print("Write", self, command_signature, arguments)

	local command_table = PYRITION.CommandRegistry[command_signature]

	self:WriteBool(true)
	self:WriteEnumeratedString("PyritionCommandSignature", command_signature)

	for index, argument_settings in ipairs(command_table.Arguments) do
		if argument_settings.Write then argument_settings:Write(self, arguments[index]) end
	end

	self:Send()
end

PYRITION:NetStreamModelRegister("PyritionCommandExecute", SHARED, MODEL)
