--globals
PYRITION.CommandArgumentRegistry = PYRITION.CommandArgumentRegistry or {}

--pyrition functions
function PYRITION:CommandArgumentParseSettings(arguments_settings)
	--string.find("Integer Default = A Minimum = 2 Maximum = 10 Unsigned", "%f[%w]%w-%s*=%s*%w+[%W]"

	print("arguments_settings", arguments_settings)
	if isstring(arguments_settings) then
		local fields = {}
		local presence = {}
		local new_settings = {}

		arguments_settings = string.gsub(arguments_settings, "%f[%w](%w-%s*=%s*%w+)[%W]", function(match)
			local key, value = select(3, string.find(match, "(%w-)%s*=%s*(%w+)"))
			fields[key] = value

			return ""
		end)

		string.gsub(arguments_settings, "%w+", function(match)
			presence[match] = true

			return ""
		end)

		print("fields")
		PrintTable(fields)

		print("presence")
		PrintTable(presence)

		arguments_settings = {}
	end

	print("arguments_settings", arguments_settings)

	assert(istable(arguments_settings), "make error message") --TODO: make error message
end

function PYRITION:CommandArgumentSignature(argument_settings)

end

function PYRITION:HOOK_CommandArgumentRegister(name, argument_table)
	self.CommandArgumentRegistry[name] = argument_table

	-- code ...
end

--post
PYRITION:GlobalHookCreate("CommandArgumentRegister")