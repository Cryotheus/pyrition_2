local language_options = PYRITION.LanguageOptions or {}
local language_options_colored = PYRITION.LanguageOptionsColored or {}

--pyrition functions
function PYRITION:LanguageDisplay(option, key, phrases)
	local operation = self.LanguageOptions[option]
	
	assert(operation, 'ID10T-4/C: Invalid language option "' .. tostring(option) .. '"')
	
	return operation(
		self.LanguageOptionsColored[option] and self:LanguageFormatColor(key, phrases) or self:LanguageFormat(key, phrases),
		key,
		phrases
	)
end

function PYRITION:LanguageList(items)
	if items.IsPlayerList then return self:LanguageListPlayers(items) end
	
	local count = #items
	
	if count == 0 then return language.GetPhrase("pyrition.list.nothing")
	elseif count == 1 then return items[1]
	elseif count == player.GetCount() then return language.GetPhrase("pyrition.list.everything")
	elseif count == 2 then return self:LanguageFormat("pyrition.list.duo", {alpha = items[1], bravo = items[2]}) end
		
	return self:LanguageFormat("pyrition.list", {
		items = table.concat(items, language.GetPhrase("pyrition.list.seperator"), 1, count - 1),
		last_item = items[count]
	})
end

function PYRITION:LanguageListPlayers(players)
	local count = #players
	local names = {}
	
	for index, item in ipairs(players) do names[index] = item:IsValid() and item:Name() or language.GetPhrase("pyrition.player.unknown") end
	
	if count == 0 then return language.GetPhrase("pyrition.player.list.nobody")
	elseif count == 1 then return names[1]
	elseif count == player.GetCount() then return language.GetPhrase("pyrition.player.list.everyone")
	elseif count == 2 then return self:LanguageFormat("pyrition.player.list.duo", {alpha = names[1], bravo = names[2]}) end
	
	return self:LanguageFormat("pyrition.player.list", {
		last_name = names[count],
		names = table.concat(names, language.GetPhrase("pyrition.player.list.seperator"), 1, count - 1)
	})
end

function PYRITION:LanguageQueue(ply, key, phrases, option) self:LanguageDisplay(option or "chat", key, phrases) end

function PYRITION:LanguageTranslate(key, fallback, phrases)
	local translated = language.GetPhrase(key)
	
	if fallback and translated == key then translated = fallback end
	
	return self:LanguageFormatTranslated(translated, phrases)
end