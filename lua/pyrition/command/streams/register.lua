local MODEL = {Priority = 60}

function MODEL:InitialSync() return next(PYRITION.CommandRegistry) ~= nil end

function MODEL:Read()
	for index = 0, self:ReadUInt(PYRITION.NetEnumerationBits.CommandSignature) do
		local arguments = {}

		local command_signature = self:ReadEnumeratedString("CommandSignature")
		local name, argument_classes, argument_signature = PYRITION:CommandSplitSignature(command_signature)

		for index, class in ipairs(argument_classes) do
			local argument = PYRITION:CommandArgumentCreate(class)
			table.insert(arguments, argument)

			if argument.Initialize then argument:Initialize() end
			if argument.ReadSettings then argument:ReadSettings(self) end
			if argument.Setup then argument:Setup() end
		end

		PYRITION:CommandDownload(name, {
			Arguments = arguments,
			ArgumentSignature = argument_signature,
			Name = name,
			Signature = command_signature,
		})
	end
end

function MODEL:Write()
	self:WriteUInt(table.Count(PYRITION.CommandRegistry) - 1, PYRITION.NetEnumerationBits.CommandSignature)

	for command_signature, command_table in pairs(PYRITION.CommandRegistry) do
		self:WriteEnumeratedString("CommandSignature", command_signature)

		for index, argument in ipairs(command_table.Arguments) do
			if argument.WriteSettings then argument:WriteSettings(self) end
		end
	end

	self:Complete()
end

PYRITION:NetStreamModelRegister("CommandRegister", CLIENT, MODEL)
