--locals
local ARGUMENT = {
	ParseSettingMacros = {
		Default = PYRITION_COMMAND_ARGUMENT_SETTING_PRESENT,
		Selfless = PYRITION_COMMAND_ARGUMENT_SETTING_PRESENT,
		Single = PYRITION_COMMAND_ARGUMENT_SETTING_PRESENT,
	}
}

--argument functions
function ARGUMENT:Complete(_executor, argument)

end

function ARGUMENT:Filter(_executor, argument)

end

function ARGUMENT:GetDefault(executor) return not self.Selfless and executor end

function ARGUMENT:Read(stream)

end

function ARGUMENT:ReadSettings(stream)

end

function ARGUMENT:Write(stream, value)

end

function ARGUMENT:WriteSettings(stream)

end

--post
PYRITION:ConsoleCommandArgumentRegister("Player", ARGUMENT)