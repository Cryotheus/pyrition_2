--locals
local language_colors = PYRITION.LanguageColors or {}
local language_options = PYRITION.LanguageOptions or {}
local language_options_colored = PYRITION.LanguageOptionsColored or {}
local language_kieves = PYRITION.LanguageKieves or {}
local local_player = SERVER and game.GetWorld() or LocalPlayer()

--colors, stolen from ULX >:D
local color_default = Color(151, 211, 255)
local color_command = Color(224, 128, 64)
local color_console = Color(255, 64, 64)
local color_self = Color(75, 0, 130)
local color_everyone = Color(0, 128, 128)
local color_player = Color(255, 224, 0)
local color_unknown = Color(192, 0, 0)
local color_misc = Color(0, 255, 0)

--globals
PYRITION.LanguageColors = language_colors
PYRITION.LanguageOptions = language_options
PYRITION.LanguageOptionsColored = language_options_colored
PYRITION.LanguageKieves = language_kieves

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

local function fetch_special_replacement(index, tag, text, key_values, text_data, accumulator, phrases)
	local kieve = language_kieves[tag]
	
	if kieve then return kieve(index, text, key_values, text_data, accumulator, phrases) end
end

local function replace_tags(self, text, phrases, colored)
	local accumulator, finish, old_finish, match, start = {}, 0
	local build_text = colored and build_medial_text_colored or build_medial_text
	local texts = {}
	
	repeat
		old_finish = finish
		start, finish, match = string.find(text, "%[%:(.-)%]", finish)
		
		if match then
			local postfix
			local prefix
			local boom = string.Split(match, ":")
			local tag = table.remove(boom, 1)
			local key_values = {}
			
			for index, gib in ipairs(boom) do
				local boom = string.Split(gib, "=")
				local key = table.remove(boom, 1)
				local value = table.remove(boom, 1)
				
				if key == "elpend" then postfix = value
				elseif key == "elfix" then prefix = value
				else key_values[key] = next(boom) and boom or value end
			end
			
			build_text(accumulator, text, old_finish, start - 1)
			
			table.insert(accumulator, {
				color = colored and (language_colors[tag] or color_default),
				key_values = next(key_values) and key_values or nil,
				prefix = prefix,
				postfix = postfix,
				tag = tag,
				text = phrases[tag] or "[>" .. tag .. "<]"
			})
		else build_text(accumulator, text, old_finish, #text) end
	until match == nil
	
	for index, text_data in ipairs(accumulator) do
		local color = text_data.color
		local key_values = text_data.key_values
		local new_text, new_color
		local perform_concatenation = true
		local text = text_data.text
		
		--in case a kieve function needs the text before it was changed by a previous kieve function
		text_data.original = text
		
		if key_values then
			new_text, new_color = fetch_special_replacement(index, text_data.tag, text, key_values, text_data, accumulator, phrases)
			
			if new_text then perform_concatenation = false end
		end
		
		--for elfix and elpend tag key values
		if perform_concatenation then
			local prefix, postfix = text_data.prefix, text_data.postfix
			
			if prefix then text = prefix .. text end
			if postfix then text = text .. postfix end
		end
		
		--convert tables of singles into their value, or multi-value tables into strings
		if istable(text) then
			if #text == 1 then text = text[1]
			else new_text = IsEntity(text[1]) and self:LanguageListPlayers(text) or self:LanguageList(text) end
		end
		
		--convert world/player to string
		if IsEntity(text) then
			if text == game.GetWorld() then
				new_color = color_console
				new_text = language.GetPhrase("pyrition.console")
			elseif text:IsValid() then new_text = text:Name()
			else
				new_text = language.GetPhrase("pyrition.player.unknown")
				new_color = color_unknown
			end
		end
		
		if color then table.insert(texts, new_color or color) end
		
		table.insert(texts, new_text or text)
	end
	
	return colored and texts or table.concat(texts, "")
end

--kieve functions
local function kieve_executor(index, text, key_values, text_data, accumulator, phrases)
	if text == local_player then return key_values.you, color_self
	elseif text == game.GetWorld() then return key_values.console, color_console end
end

local function kieve_targets(index, text, key_values, text_data, accumulator, phrases)
	if text == language.GetPhrase("pyrition.player.list.everyone") then return nil, color_everyone end
	
	local executor = phrases.executor --who ran the command
	local ply = local_player
	local themself = text == executor and key_values.themself --the text to use if target is the executor
	local value_self = executor and key_values.self --the text to use if we're the target and executor
	local you = text == ply and key_values.you --the text to use if we're the target
	
	if value_self and you and executor == ply then return value_self, color_self
	elseif you then return you, color_self
	elseif themself then return themself, color_player end
end

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

function PYRITION:PyritionLanguageRegisterColor(color, ...) for index, tag in ipairs{...} do language_colors[tag] = color end end

function PYRITION:PyritionLanguageRegisterOption(option, operation, colored) --options are the media of message delivery
	language_options[option] = operation
	language_options_colored[option] = colored or nil
	
	if CLIENT then return end
	
	self:NetAddEnumeratedString("language_options", option)
end

function PYRITION:PyritionLanguageRegisterKieve(kieve_function, ...) for index, tag in ipairs{...} do language_kieves[tag] = kieve_function end end

--hooks
hook.Add("InitPostEntity", "PyritionLanguage", function() local_player = SERVER and game.GetWorld() or LocalPlayer() end)

--post
PYRITION:GlobalHookCreate("LanguageRegisterColor")
PYRITION:GlobalHookCreate("LanguageRegisterOption")
PYRITION:GlobalHookCreate("LanguageRegisterKieve")

PYRITION:LanguageRegisterColor(color_command, "command")
PYRITION:LanguageRegisterColor(color_misc, "duration", "map", "reason", "time")
PYRITION:LanguageRegisterColor(color_player, "executor", "player", "target", "targets")

PYRITION:LanguageRegisterKieve(kieve_executor, "executor")
PYRITION:LanguageRegisterKieve(kieve_targets, "target", "targets")

PYRITION:LanguageRegisterOption("center", function(formatted, key, phrases) local_player:PrintMessage(HUD_PRINTCENTER, formatted) end)
PYRITION:LanguageRegisterOption("chat", function(formatted_table, key, phrases) chat.AddText(unpack(formatted_table)) end, true)
PYRITION:LanguageRegisterOption("console", function(formatted, key, phrases) MsgC(color_white, formatted, "\n") end)