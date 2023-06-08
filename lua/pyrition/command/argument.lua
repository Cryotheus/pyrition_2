--local functions
local function numerical_list(value)
	local numbers = string.Explode(value, "%s+", true)

	for index, number in ipairs(numbers) do
		local converted = tonumber(number)
		assert(converted, "Failed to convert argument macro to numerical value: " .. tostring(number))

		numbers[index] = converted
	end

	return numbers
end

PYRITION.CommandArgumentMacroRegistry = PYRITION.CommandArgumentMacroRegistry or {}
PYRITION.CommandArgumentRegistry = PYRITION.CommandArgumentRegistry or {}

function PYRITION:CommandArgumentCreate(class)
	local argument_meta = self.CommandArgumentRegistry[class]

	return setmetatable({Class = class}, argument_meta.InstanceMetaTable)
end

function PYRITION:CommandArgumentParseSettings(settings)
	local argument

	if isstring(settings) then
		argument = {}
		local class
		local fields = {}
		local presence = {}

		--find key values in apostrophes
		settings = string.gsub(settings, "%f[%w](%w-)%s*=%s*'(.-)'", function(key, value)
			fields[key] = value

			return ""
		end)

		--find simple key values
		settings = string.gsub(settings, "%f[%w](%w-)%s*=%s*(%w+)[%W]", function(key, value)
			fields[key] = value

			return ""
		end)

		--find presence keys
		string.gsub(settings, "%w+", function(match)
			if class then table.insert(presence, match)
			else class = match end

			return ""
		end)

		local argument_meta = self.CommandArgumentRegistry[class]

		assert(argument_meta, "Missing command argument meta for class " .. tostring(class))
		setmetatable(argument, argument_meta.InstanceMetaTable)

		if argument.Initialize then argument:Initialize() end

		local conversion_functions = self.CommandArgumentMacroRegistry
		local setting_macros = argument.ParseSettingMacros

		for index, key in ipairs(presence) do if setting_macros[key] == "Present" then argument[key] = true end end
		for key, value in pairs(fields) do argument[key] = conversion_functions[setting_macros[key]](value) end

		argument.Class = class
	elseif istable(settings) then
		local class = settings.Class

		assert(class, "CommandArgumentParseSettings missing Class field for table type argument setting.")

		local argument_meta = self.CommandArgumentRegistry[class]

		assert(argument_meta, "Missing command argument meta for class " .. tostring(class))
		setmetatable(argument, argument_meta.InstanceMetaTable)

		if argument.Initialize then argument:Initialize() end
	end

	if argument.Setup then argument:Setup() end

	return argument
end

function PYRITION:HOOK_CommandArgumentRegister(name, argument_table)
	assert(isstring(name), "CommandArgumentRegister argument #1 must be a string.")
	assert(istable(argument_table), "CommandArgumentRegister argument #1 must be a table.")

	argument_table.InstanceMetaTable = {__index = argument_table}
	self.CommandArgumentRegistry[name] = argument_table
end

function PYRITION:HOOK_CommandArgumentRegisterMacro(name, conversion_function) self.CommandArgumentMacroRegistry[name] = conversion_function end

PYRITION:GlobalHookCreate("CommandArgumentRegister")
PYRITION:GlobalHookCreate("CommandArgumentRegisterMacro")

PYRITION:CommandArgumentRegisterMacro("Angle", function(value) return Angle(unpack(numerical_list(value))) end)
PYRITION:CommandArgumentRegisterMacro("Boolean", tobool)
PYRITION:CommandArgumentRegisterMacro("Color", function(value) return Color(unpack(numerical_list(value))) end)
PYRITION:CommandArgumentRegisterMacro("Numerical", tonumber)
PYRITION:CommandArgumentRegisterMacro("NumericalList", numerical_list)
PYRITION:CommandArgumentRegisterMacro("String", function(value) return value end)
PYRITION:CommandArgumentRegisterMacro("Vector", function(value) return Vector(unpack(numerical_list(value))) end)
