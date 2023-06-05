--locals
local ARGUMENT = {
	ParseSettingMacros = {
		Default = "Numerical",
		Maximum = "Numerical",
		Minimum = "Numerical",
		Signed = "Present",
	},
}

--post
PYRITION:CommandArgumentRegister("Integer", ARGUMENT)