--locals
local ARGUMENT = {
	ParseSettingMacros = {
		Default = "Present",
		Selfless = "Present",
		Single = "Present",
	},
}

--[[
	Complete - return a list of strings for possible completions
	Filter - turns a string into a success bool and a value of the appropriate type
	GetDefault
	Read
	ReadSettings
	Write
	WriteSettings
]]

--argument methods
function ARGUMENT:Complete(_executor, argument)

	return {}
end

function ARGUMENT:Filter(_executor, argument)
	--should return a value for if the filter passed
	--and a second value of the filtered result
	--eg. we convert ` : string -> success: boolean, player: Player`

	return false
end

--post
PYRITION:CommandArgumentRegister("Player", ARGUMENT)