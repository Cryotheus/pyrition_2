local language_options = PYRITION.LanguageOptions or {}
local language_options_colored = PYRITION.LanguageOptionsColored or {}

--pyrition functions
function PYRITION:LanguageDisplay(option, key, phrases)
	local operation = language_options[option]
	
	assert(operation, debug.Trace() or 'ID10T-4/C: Invalid language option "' .. tostring(option) .. '"')
	
	return operation(
		language_options_colored[option] and self:LanguageFormatColor(key, phrases) or self:LanguageFormat(key, phrases),
		key,
		phrases
	)
end

function PYRITION:LanguageQueue(ply, key, phrases, option) self:LanguageDisplay(option or "chat", key, phrases) end