local COMMAND = PYRITION.CommandMetaTable or {}
COMMAND.InstanceMetaTable = {__index = COMMAND}
PYRITION.CommandMetaTable = COMMAND

function COMMAND:Write(stream, executor, arguments)
	local arguments_settings = self.Arguments

	stream:WriteString(self.Signature)
	
	for index, argument_settings in ipairs(arguments_settings) do
		arguments_settings:Write(stream, arguments[index])
	end
end

function COMMAND:WriteRegistration(stream)
	local arguments_settings = self.Arguments

	stream:WriteString(self.Name)
	stream:WriteString(self.ArgumentSignature)
end