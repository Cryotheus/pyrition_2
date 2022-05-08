local language_options = PYRITION.LanguageOptions or {}

--globals
PYRITION.LanguageOptions = language_options

--pyrition functions
function PYRITION:LanguageFormat(key, phrases)
	if phrases then return (string.gsub(language.GetPhrase(key), "%[%:(.-)%]", phrases))
	else return language.GetPhrase(key) end
end

function PYRITION:LanguageRegisterOption(option, operation)
	language_options[option] = operation
	
	if CLIENT then return end
	
	self:NetAddEnumeratedString("language_options", option)
end

--post
PYRITION:LanguageRegisterOption("center", function(formatted, key, phrases) LocalPlayer():PrintMessage(HUD_PRINTCENTER, formatted) end)
PYRITION:LanguageRegisterOption("chat", function(formatted, key, phrases) chat.AddText(color_white, formatted) end)
PYRITION:LanguageRegisterOption("console", function(formatted, key, phrases) MsgC(color_white, formatted, "\n") end)