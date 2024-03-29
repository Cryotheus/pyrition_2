local language_options = PYRITION.LanguageOptions or {}
local language_options_colored = PYRITION.LanguageOptionsColored or {}

function PYRITION:LanguageDisplay(option, key, phrases)
	local operation = language_options[option]

	assert(operation, "Invalid language option '" .. tostring(option) .. "'")

	return operation(
		language_options_colored[option] and self:LanguageFormatColor(key, phrases) or self:LanguageFormat(key, phrases),
		key,
		phrases
	)
end

function PYRITION:LanguageQueue(_ply, key, phrases, option) self:LanguageDisplay(option or "Chat", key, phrases) end