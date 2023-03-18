--locals
local ARGUMENT = {
	ParseSettingMacros = {
		Default = PYRITION_COMMAND_ARGUMENT_SETTING_NUMERICAL,
		Maximum = PYRITION_COMMAND_ARGUMENT_SETTING_NUMERICAL,
		Minimum = PYRITION_COMMAND_ARGUMENT_SETTING_NUMERICAL,
		Signed = PYRITION_COMMAND_ARGUMENT_SETTING_BOOLEAN,
	}
}

--argument functions
function ARGUMENT:Complete(_executor, argument)

end

function ARGUMENT:Filter(_executor, argument)
	argument = tonumber(argument)

	if not argument then return false, nil, "Value must be a valid number." end
	if argument ~= argument then return false, nil, "Value must not be NaN." end
	if math.floor(argument) ~= argument then return false, nil, self.Signed and "Value must be an integer." or "Value must be a whole number." end

	local maximum = self.Maximum

	if maximum and argument > maximum then return false, nil, "Value must not be greater than [:maximum].", {maximum = maximum} end

	local minimum = self.Minimum

	if minimum and argument > minimum then return false, nil, "Value must not be smaller than [:minimum].", {minimum = minimum} end

	return true, argument
end

function ARGUMENT:ParsedSettings()
	local maximum = self.Maximum or 4294967295
	local minimum = math.max(0, self.Minimum or 0)

	self.NetworkBits = math.ceil(math.log(maximum - minimum, 2))
	self.NetworkMaximum = maximum
	self.NetworkMinimum = minimum
end

function ARGUMENT:Read(stream)
	if self.Signed and stream:ReadBool() then return -stream:ReadUInt(self.NetworkBits) - self.NetworkMinimum end

	return stream:ReadUInt(self.NetworkBits) + self.NetworkMinimum
end

function ARGUMENT:ReadSettings(stream)
	local signed = stream:ReadBool()
	local method = signed and "ReadLong" or "ReadULong"

	self.Default = stream:MaybeRead(method)
	self.Maximum = stream:MaybeRead(method)
	self.Minimum = stream:MaybeRead(method)
	self.Signed = signed
end

function ARGUMENT:Write(stream, value)
	if self.Signed then
		local absolute_value = math.abs(value)

		stream:WriteBool(value < 0)
		stream:WriteUInt(absolute_value - self.NetworkMinimum, self.NetworkBits)
	else stream:WriteUInt(value - self.NetworkMinimum, self.NetworkBits) end
end

function ARGUMENT:WriteSettings(stream)
	local signed = self.Signed
	local method = signed and "ReadLong" or "ReadULong"

	stream:WriteBool(signed)
	stream:MaybeWrite(method, self.Default)
	stream:MaybeWrite(method, self.Maximum)
	stream:MaybeWrite(method, self.Minimum)
end

--post
PYRITION:ConsoleCommandArgumentRegister("Integer", ARGUMENT)