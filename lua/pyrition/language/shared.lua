local language_options = PYRITION.LanguageOptions or {}

--globals
PYRITION.LanguageOptions = language_options

--local functions
local function replace_tags(text, phrases) return (string.gsub(text, "%[%:(.-)%]", phrases)) end

--pyrition functions
function PYRITION:LanguageFormat(key, phrases) return phrases and replace_tags(language.GetPhrase(key), phrases) or language.GetPhrase(key) end
function PYRITION:LanguageFormatTranslated(text, phrases) return phrases and replace_tags(text, phrases) or text end

function PYRITION:LanguageRegisterOption(option, operation) --options are the media of message delivery
	language_options[option] = operation
	
	if CLIENT then return end
	
	self:NetAddEnumeratedString("language_options", option)
end

--post
PYRITION:LanguageRegisterOption("center", function(formatted, key, phrases) LocalPlayer():PrintMessage(HUD_PRINTCENTER, formatted) end)
PYRITION:LanguageRegisterOption("chat", function(formatted, key, phrases) chat.AddText(color_white, formatted) end)
PYRITION:LanguageRegisterOption("console", function(formatted, key, phrases) MsgC(color_white, formatted, "\n") end)