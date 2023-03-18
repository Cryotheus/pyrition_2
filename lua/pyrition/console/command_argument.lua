--globals
PYRITION.ConsoleCommandArgumentClasses = PYRITION.ConsoleCommandArgumentClasses or {}
PYRITION.ConsoleCommandArgumentSettings = PYRITION.ConsoleCommandArgumentSettings or {}
PYRITION.ConsoleCommandArgumentSettingMethods = PYRITION.ConsoleCommandArgumentSettingMethods or {}

--pyrition functions
function PYRITION:ConsoleCommandArgumentGetSettingMacro(enumeration)
	if isstring(enumeration) then enumeration = _G[enumeration] or _G["PYRITION_COMMAND_ARGUMENT_SETTING_" .. enumeration] end

	return self.ConsoleCommandArgumentSettingMethods[enumeration]
end

function PYRITION:ConsoleCommandArgumentParse(text)
	local words = string.Split(text, " ")
	local class = table.remove(words, 1)

	local argument_object = setmetatable({Class = class}, {__index = self.ConsoleCommandArgumentClasses[class]})

	for index, word in ipairs(words) do
		local split = string.Explode("%s*=%s*", word, true)
		local key = table.remove(split, 1)
		local values
		local values_string = split[1]

		if values_string then values = string.Explode(",%s+", values_string, true) end

		argument_object[key] = argument_object["ParseSetting" .. key](argument_object, values)
	end

	if argument_object.ParsedSettings then argument_object:ParsedSettings() end

	return argument_object
end

function PYRITION:ConsoleCommandArgumentRegisterSettingMacro(global_key, method)
	local enumeration = duplex.Insert(self.ConsoleCommandArgumentSettings, global_key)

	_G["PYRITION_COMMAND_ARGUMENT_SETTING_" .. global_key] = enumeration
	self.ConsoleCommandArgumentSettingMethods[enumeration] = method
end

function PYRITION:ConsoleCommandArgumentsValidate(executor, command, signature_index, arguments)
	local argument_list = command.Arguments[signature_index]
	local required_arguments = argument_list.Required or 0

	for argument_index, argument_object in ipairs(argument_list) do
		local argument = arguments[argument_index]
		local required = argument_index <= required_arguments
		local valid_argument, value, message, phrases

		if not argument then
			value = argument.Default

			--if the default value is true, that means we should try to call this function
			--if the function isn't define, the default value is literally true
			if value == true and argument.GetDefault then value = argument:GetDefault(executor) end

			if value == nil then
				if required then
					--if there's no default and it's required, return an error
					return false, "Could not get a default value for argument #[:index], a required argument.", {index = argument_index}
				end
			else valid_argument = true end
		else valid_argument, value, message, phrases = argument:Filter(executor, argument) end

		if not valid_argument then
			if required then
				if phrases then
					phrases.executor = executor
					phrases.index = argument_index

					return false, message, phrases
				end

				return false, message, {
					executor = executor,
					index = argument_index
				}
			else arguments[argument_index] = nil end
		end

		arguments[argument_index] = value
	end

	return true
end

--pyrition hooks
function PYRITION:PyritionConsoleCommandArgumentRegister(class, argument_table)
	for key, enumeration in pairs(argument_table.ParseSettingMacros or {}) do
		--replace the macro enumeration with the actual function
		argument_table["ParseSetting" .. key] = self:ConsoleCommandArgumentGetSettingMacro(enumeration)
	end

	argument_table.ParseSettingMacros = nil --only used during setup - destroy it now that we're done
	local existing_table = self.ConsoleCommandArgumentClasses[class]

	--maintain reference since we use these as the __index for the argument metatables
	if existing_table then table.CopyFromTo(existing_table, argument_table)
	else self.ConsoleCommandArgumentClasses[class] = argument_table end
end

--post
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("ANGLE", function(_self, values) return Angle(values[1], values[2], values[3]) end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("BOOLEAN", function(_self, values) return tobool(values[1]) end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("COLOR", function(_self, values) return Angle(values[1], values[2], values[3], values[4] or 255) end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("NUMERICAL", function(_self, values) return tonumber(values[1]) end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("NUMERICAL_LIST", function(_self, values) for index, value in ipairs(values) do values[index] = tonumber(value) end return values end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("STRING", function(_self, values) return values[1] end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("NUMERICAL_LIST", function(_self, values) return values end)
PYRITION:ConsoleCommandArgumentRegisterSettingMacro("VECTOR", function(_self, values) return Vector(values[1], values[2], values[3]) end)
PYRITION:GlobalHookCreate("ConsoleCommandArgumentRegister")