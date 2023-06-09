local color_broadcast = Color(255, 255, 0)
local color_silent = Color(0, 0, 255)
local log_filter = PYRITION.LanguageLogFilter or {}

PYRITION.LanguageLogFilter = log_filter

function PYRITION:LanguageDisplay(log, key, phrases, broadcast)
	if isstring(log) then log = log_filter[log] and true or false end

	--if prefixed with #, localize the string
	--if the # is wanted, a backslash can be used to escape like "\\#pyrition.commands.heal" weirdo
	if phrases then
		for tag, phrase in pairs(phrases) do
			if isstring(phrase) then
				if string.StartWith(phrase, "\\#") then phrases[tag] = string.sub(phrase, 2)
				elseif string.StartWith(phrase, "#") then phrases[tag] = language.GetPhrase(string.sub(phrase, 2))
				else phrases[tag] = phrase end
			end
		end
	end

	if log then ServerLog(language.GetPhrase("pyrition.language.log") .. self:LanguageFormat(key, phrases) .. "\n")
	else
		if broadcast then MsgC(color_broadcast, language.GetPhrase("pyrition.language.broadcast"))
		else MsgC(color_silent, language.GetPhrase("pyrition.language")) end

		MsgC(unpack(self:LanguageFormatColor(key, phrases)))
		MsgC("\n")
	end
end

function PYRITION:LanguageQueue(ply, key, phrases, option)
	assert(not option or self.NetEnumeratedStrings.language_options[option], "Cannot queue language component message for non-existent option '" .. tostring(option) .. "'")

	--having ply = true means to broadcast to everyone
	if ply == true then
		--RELEASE: send messages only to loaded players
		for index, ply in ipairs(player.GetHumans()) do self:LanguageQueue(ply, key, phrases, option) end

		--send the broadcast to console
		return self:LanguageDisplay("messaging", key, phrases, true)
	end

	if istable(ply) then
		for index, entry in ipairs(ply) do self:LanguageQueue(entry, key, phrases, option) end

		return self:LanguageDisplay("messaging", key, phrases)
	end

	--if the ply is the server
	if ply == nil or ply == game.GetWorld() or ply:EntIndex() == 0 then return self:LanguageDisplay(false, key, phrases) end

	--get an existing stream model or create one, then write the message to it
	self:NetStreamModelGet("PyritionLanguage", ply)(key, phrases, option or "Chat")
end

function PYRITION:LanguageRegister(key) self:NetAddEnumeratedString("PyritionLanguage", key) end
function PYRITION:LanguageRegisterLogFilter(key, enabled) log_filter[key] = enabled end

PYRITION:NetAddEnumeratedString("PyritionLanguage")