--locals
local language_colors = PYRITION.LanguageColors or {}
local language_options = PYRITION.LanguageOptions or {}
local language_options_colored = PYRITION.LanguageOptionsColored or {}
local language_kieves = PYRITION.LanguageKieves or {}
local language_tieves = PYRITION.LanguageTieves or {}
local local_player = SERVER and game.GetWorld() or LocalPlayer()
local nice_time = PYRITION._TimeNicefy

--colors sto- "inspired" by ULX
local color_command = Color(224, 128, 64)
local color_console = Color(255, 64, 64)
local color_default = Color(255, 230, 196)
local color_everyone = Color(0, 128, 128)
local color_misc = Color(224, 255, 0)
local color_player = Color(255, 224, 0)
local color_self = SERVER and color_console or Color(75, 0, 130)
local color_unknown = Color(192, 0, 0)

--local tables
local colors = {
	command = color_command,
	console = color_console,
	default = color_default,
	everyone = color_everyone,
	misc = color_misc,
	player = color_player,
	self = color_self,
	unknown = color_unknown
}

local global_kieves = {
	append = true,
	elfix = true,
	elpend = true,
	prefix = true
}

--local functions
local function build_medial_text(accumulator, text, last_finish, current_start)
	local medial_text = string.sub(text, last_finish + 1, current_start)

	if medial_text == "" then return end

	table.insert(accumulator, {text = medial_text})
end

local function build_medial_text_colored(accumulator, text, last_finish, current_start)
	local medial_text = string.sub(text, last_finish + 1, current_start)

	if medial_text == "" then return end

	table.insert(accumulator, {
		color = color_default,
		text = medial_text
	})
end

local function fetch_special_replacement(tag, ...)
	local kieve = language_kieves[tag]

	if kieve then return kieve(...) end
end

local function get_color(id)
	local id_color = colors[id] or language_colors[id]

	if id_color then return id_color end

	id = string.gsub(id, "%s", "")
	local rgb = string.Split(id, ",")

	if #rgb == 3 then return Color(tonumber(rgb[1]), tonumber(rgb[2]), tonumber(rgb[3])) end
	--maybe I should also allow hex?
end

local function global_kieve_append(text, texts, postfix, postfix_color)
	if postfix_color then
		table.insert(texts, get_color(postfix_color))
		table.insert(texts, postfix)
	else texts[#texts] = text .. postfix end
end

local function global_kieve_prefix(text, texts, prefix, prefix_color)
	if prefix_color then
		table.insert(texts, get_color(prefix_color))
		table.insert(texts, prefix)
	else return prefix .. text end
end

local function phrase_exists(key)
	local phrase = language.GetPhrase(key)

	return phrase ~= key and phrase
end

local function replace_tags(self, text, phrases, colored)
	local accumulator, finish, old_finish, match, start = {}, 0
	local build_text = colored and build_medial_text_colored or build_medial_text
	local texts = {}

	--if prefixed with #, localize the string
	--if the # is wanted, a backslash can be used to escape like "\\#pyrition.commands.heal"
	for tag, phrase in pairs(phrases) do
		if isstring(phrase) then
			if string.StartWith(phrase, "\\#") then phrases[tag] = string.sub(phrase, 2)
			elseif string.StartWith(phrase, "#") then phrases[tag] = language.GetPhrase(string.sub(phrase, 2))
			else phrases[tag] = phrase end
		elseif istable(phrase) and #phrase == 1 then phrases[tag] = phrase[1] end
	end

	repeat
		old_finish = finish
		start, finish, match = string.find(text, "%[%:(.-)%]", finish)

		if match then
			local global_key_values = {}
			local postfix
			local postfix_color
			local prefix
			local prefix_color
			local boom = string.Split(match, ":")
			local tag = table.remove(boom, 1)
			local key_values = {}

			for index, gib in ipairs(boom) do
				local boom = string.Split(gib, "=")
				local key = table.remove(boom, 1)
				local value = boom[1]

				if global_kieves[key] then global_key_values[key] = boom
				else key_values[key] = #boom > 1 and boom or value or true end
			end

			build_text(accumulator, text, old_finish, start - 1)

			table.insert(accumulator, {
				color = colored and (language_colors[tag] or color_default),
				global_key_values = next(global_key_values) and global_key_values or nil,
				key_values = next(key_values) and key_values or nil,
				postfix = postfix,
				postfix_color = postfix_color and get_color(postfix_color),
				prefix = prefix,
				prefix_color = prefix_color and get_color(prefix_color),
				tag = tag,
				text = phrases[tag] or "[:" .. tag .. "]"
			})
		else build_text(accumulator, text, old_finish, #text) end
	until match == nil

	for index, text_data in ipairs(accumulator) do
		local color = text_data.color
		local global_key_values = text_data.global_key_values
		local key_values = text_data.key_values
		local new_text, new_color
		local replacements_made = false
		local tag = text_data.tag
		local text = text_data.text
		local tieve_function = language_tieves[tag]

		--in case a kieve function needs the text before it was changed by a previous kieve function
		text_data.original = text

		--convert tables of singles into their value, or multi-value tables into strings
		if tieve_function then text = tieve_function(index, text, text_data, texts, key_values, phrases) or text end

		if istable(text) then
			if #text == 1 then text = text[1]
			else text = IsEntity(text[1]) and self:LanguageListPlayers(text) or self:LanguageList(text) end
		end

		if key_values then
			--index, text, texts, key_values, text_data, phrases
			--index, text, texts, key_values, text_data, phrases
			new_text, new_color = fetch_special_replacement(tag, index, text, text_data, texts, key_values, phrases)

			if new_text then
				replacements_made = true
				text = new_text
			end
		end

		--convert world/player to string
		if IsEntity(text) then
			if text == game.GetWorld() then
				color = colored and color_console
				text = language.GetPhrase("pyrition.console")
			elseif text:IsValid() then text = text:Name()
			else
				color = colored and color_unknown
				text = language.GetPhrase("pyrition.player.unknown")
			end
		end

		--for elfix and elpend tag key values
		if global_key_values then
			local postfix_index = replacements_made and "append" or "elpend"
			local postfix_values = global_key_values[postfix_index]
			local prefix_index = replacements_made and "prefix" or "elfix"
			local prefix_values = global_key_values[prefix_index]

			if prefix_values then text = global_kieve_prefix(text, texts, unpack(prefix_values)) or text end
			if color then table.insert(texts, new_color or color) end

			table.insert(texts, text)

			if postfix_values then global_kieve_append(text, texts, unpack(postfix_values)) end
		else
			if color then table.insert(texts, new_color or color) end

			table.insert(texts, text)
		end
	end

	return colored and texts or table.concat(texts, "")
end

--kieve functions
local function kieve_player(_index, text, _text_data, _texts, key_values, _phrases)
	if text == local_player then return key_values.you, color_self
	elseif text == game.GetWorld() then return key_values.console, color_console end

	if key_values.possessive then
		if IsEntity(text) then text = text:Name() end
		if string.Right(text, 1) == "s" then return text .. "'" end

		return text .. "'s"
	end
end

local function kieve_targets(_index, text, text_data, _texts, key_values, phrases)
	local everyone = language.GetPhrase("pyrition.player.list.everyone")

	if text == everyone then return nil, color_everyone end

	if key_values.selfless then
		local original = text_data.original

		if istable(original) and player.GetCount() - #original == 1 then return everyone, color_everyone end
	end

	local executor = phrases.executor --who ran the command
	local ply = local_player
	local themself = text == executor and key_values.themself --the text to use if target is the executor
	local value_self = executor and key_values.self --the text to use if we're the target and executor
	local you = text == ply and key_values.you --the text to use if we're the target

	if value_self and you and executor == ply then return value_self, color_self
	elseif you then return you, color_self
	elseif themself then return themself, color_player end
end

local function tieve_time(_index, text, _text_data, _texts, _key_values, _phrases)
	local time = tonumber(text)

	if time then return nice_time(time, 1) end
end

--globals
PYRITION.LanguageColors = language_colors
PYRITION.LanguageOptions = language_options
PYRITION.LanguageOptionsColored = language_options_colored
PYRITION.LanguageKieves = language_kieves
PYRITION.LanguageTieves = language_tieves
PYRITION._LanguagePhraseExists = phrase_exists

--pyrition functions
function PYRITION:LanguageFormat(key, phrases) return phrases and replace_tags(self, language.GetPhrase(key), phrases) or language.GetPhrase(key) end
function PYRITION:LanguageFormatColor(key, phrases) return phrases and replace_tags(self, language.GetPhrase(key), phrases, true) or {color_default, language.GetPhrase(key)} end
function PYRITION:LanguageFormatColorTranslated(text, phrases) return phrases and replace_tags(self, text, phrases, true) or {color_default, text} end
function PYRITION:LanguageFormatTranslated(text, phrases) return phrases and replace_tags(self, text, phrases) or text end

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

function PYRITION:PyritionLanguageRegisterColor(color, ...)
	if isstring(color) then color = colors[color] end
	if not color then return end

	for index, tag in ipairs{...} do language_colors[tag] = color end
end

function PYRITION:PyritionLanguageRegisterKieve(kieve_function, ...)
	if isstring(kieve_function) then kieve_function = language_kieves[kieve_function] end --copy an existing kieve
	if not kieve_function then return end

	for index, tag in ipairs{...} do language_kieves[tag] = kieve_function end
end

function PYRITION:PyritionLanguageRegisterOption(option, operation, colored) --options are the media of message delivery
	language_options[option] = operation
	language_options_colored[option] = colored or nil

	if CLIENT then return end

	self:NetAddEnumeratedString("language_options", option)
end

function PYRITION:PyritionLanguageRegisterTieve(tieve_function, ...)
	if isstring(tieve_function) then tieve_function = language_tieves[tieve_function] end --copy an existing tieve
	if not tieve_function then return end

	for index, tag in ipairs{...} do language_tieves[tag] = tieve_function end
end

--hooks
hook.Add("InitPostEntity", "PyritionLanguage", function() local_player = SERVER and game.GetWorld() or LocalPlayer() end)

--post
PYRITION:GlobalHookCreate("LanguageRegisterColor")
PYRITION:GlobalHookCreate("LanguageRegisterOption")
PYRITION:GlobalHookCreate("LanguageRegisterKieve")
PYRITION:GlobalHookCreate("LanguageRegisterTieve")

PYRITION:LanguageRegisterColor(color_misc, "amount", "attempts", "class", "count", "duration", "id", "index", "message", "quantity", "reason", "thread", "time")
PYRITION:LanguageRegisterColor(color_player, "name", "player", "target", "targets")

PYRITION:LanguageRegisterKieve(kieve_player, "player")
PYRITION:LanguageRegisterKieve(kieve_targets, "target", "targets")

PYRITION:LanguageRegisterOption("center", function(formatted, _key, _phrases) local_player:PrintMessage(HUD_PRINTCENTER, formatted) end)
PYRITION:LanguageRegisterOption("chat", function(formatted_table, _key, _phrases) chat.AddText(unpack(formatted_table)) end, true)

PYRITION:LanguageRegisterOption("console", function(formatted_table)
	table.insert(formatted_table, "\n")
	MsgC(unpack(formatted_table))
end)

PYRITION:LanguageRegisterTieve(tieve_time, "time")