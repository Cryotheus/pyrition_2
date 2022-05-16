--pyrition functions
function PYRITION:LanguageDisplay(option, key, phrases)
	local formatted = self:LanguageFormat(key, phrases)
	local operation = self.LanguageOptions[option]
	
	assert(operation, 'ID10T-4/C: Invalid language option "' .. tostring(option) .. '"')
	
	return operation(formatted, key, phrases)
end

function PYRITION:LanguageList(items)
	if items.IsPlayerList then return self:LanguageListPlayers(items) end
	
	local count = #items
	
	if count == 0 then return language.GetPhrase("pyrition.list.nothing")
	elseif count == 1 then return items[1]
	elseif count == 2 then return self:LanguageFormat("pyrition.list.duo", {alpha = items[1], bravo = items[2]})
	elseif count == player.GetCount() then return language.GetPhrase("pyrition.list.everything") end
		
	return self:LanguageFormat("pyrition.list", {
		items = table.concat(items, language.GetPhrase("pyrition.list.seperator"), 1, count - 1),
		last_item = items[count]
	})
end

function PYRITION:LanguageListPlayers(names)
	local count = #names
	
	--convert any players to names
	for index, item in ipairs(names) do if IsEntity(item) and item:IsPlayer() then names[index] = item:Name() end end
	
	if count == 0 then return language.GetPhrase("pyrition.player.list.nobody")
	elseif count == 1 then return names[1]
	elseif count == 2 then return self:LanguageFormat("pyrition.player.list.duo", {alpha = names[1], bravo = names[2]})
	elseif count == player.GetCount() then return language.GetPhrase("pyrition.player.list.everyone") end
	
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