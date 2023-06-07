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
PYRITION.CommandArgumentSignatureLookup = PYRITION.CommandArgumentSignatureLookup or {}

function PYRITION:CommandArgumentParseSettings(settings)
	if isstring(settings) then
		local class
		local fields = {}
		local new_settings = {}
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
		setmetatable(new_settings, argument_meta.InstanceMetaTable)

		local conversion_functions = self.CommandArgumentMacroRegistry
		local setting_macros = new_settings.ParseSettingMacros

		for index, key in ipairs(presence) do if setting_macros[key] == "Present" then new_settings[key] = true end end
		for key, value in pairs(fields) do new_settings[key] = conversion_functions[setting_macros[key]](value) end

		new_settings.Class = class
		settings = new_settings
	elseif istable(settings) then
		local class = settings.Class

		assert(class, "CommandArgumentParseSettings missing Class field for table type argument setting.")

		local argument_meta = self.CommandArgumentRegistry[class]

		assert(argument_meta, "Missing command argument meta for class " .. tostring(class))
		setmetatable(argument, argument_meta)
	end

	return settings
end

function PYRITION:HOOK_CommandArgumentRegister(name, argument_table)
	assert(isstring(name), "CommandArgumentRegister argument #1 must be a string.")
	assert(istable(argument_table), "CommandArgumentRegister argument #1 must be a table.")

	local signature = argument_table.Signature or string.lower(name[1])

	assert(string.len(signature) == utf8.len(signature), "CommandArgumentRegister \"" .. name .. "\" signature cannot contain UTF8 specific characters.")
	assert(signature ~= "x", "CommandArgumentRegister \"" .. name .. "\" signature cannot be x.")
	assert(signature == string.lower(signature), "CommandArgumentRegister \"" .. name .. "\" signature must be lower case.")
	assert(signature ~= string.upper(signature), "CommandArgumentRegister \"" .. name .. "\" signature character must support an uppercase variant.")

	local existing_name = self.CommandArgumentSignatureLookup[signature]

	if existing_name and existing_name ~= name then error("CommandArgumentRegister found signature collision between new \"" .. name .. "\" argument signatures and existing \"" .. existing_name .. "\" argument signatures.") end

	argument_table.InstanceMetaTable = {__index = argument_table}
	argument_table.Signature = signature
	self.CommandArgumentRegistry[name] = argument_table
	self.CommandArgumentSignatureLookup[signature] = name
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