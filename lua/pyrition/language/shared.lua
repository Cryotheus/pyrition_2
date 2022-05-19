--locals
local language_colors = PYRITION.LanguageColors or {}
local language_options = PYRITION.LanguageOptions or {}
local language_options_colored = PYRITION.LanguageOptionsColored or {}
local language_kieves = PYRITION.LanguageKieves or {}

--colors, stolen from ULX >:D
local color_default = Color(151, 211, 255)
local color_command = Color(224, 128, 64)
--local color_console = Color(0, 0, 0) --unused
local color_self = Color(75, 0, 130)
local color_everyone = Color(0, 128, 128)
local color_player = Color(255, 255, 0)
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

local function text_is_ply(text, ply)
	local ply = ply or LocalPlayer()
	
	if text == ply or (not isstring(ply) and text == ply:Name()) then return true end
end

local function fetch_special_replacement(index, tag, text, key_values, text_data, accumulator)
	local kieve = language_kieves[tag]
	
	if kieve then return kieve(index, text, key_values, text_data, accumulator) end
end

local function find_executor(accumulator)
	for other_index, other_data in ipairs(accumulator) do
		local tag = other_data.tag
		
		if tag == "executor" then
			local key_values = other_data.key_values
			
			return other_data.original or other_data.text
		end
	end
end

local function kieve_executor(index, text, key_values, text_data, accumulator)
	local you = key_values.you
	
	if text_is_ply(text) then return you, color_self end
end

local function kieve_targets(index, text, key_values, text_data, accumulator)
	if text == (SERVER and "everyone" or language.GetPhrase("pyrition.player.list.everyone")) then return nil, color_everyone end
	
	key_values.themself = "themself"
	
	local executor = find_executor(accumulator) --who ran the command
	local themself = text_is_ply(text, executor) and key_values.themself --the text to use if target is the executor
	local value_self = executor and key_values.self --the text to use if we're the target and executor
	local you = text_is_ply(text) and key_values.you --the text to use if we're the target
	
	if value_self and you and text_is_ply(executor) then return value_self, color_self
	elseif you then return you, color_self
	elseif themself then return themself, color_player end
end

local function replace_tags(text, phrases, colored)
	local accumulator, finish, old_finish, match, start = {}, 0
	local build_text = colored and build_medial_text_colored or build_medial_text
	local texts = {}
	
	repeat
		old_finish = finish
		start, finish, match = string.find(text, "%[%:(.-)%]", finish)
		
		if match then
			local boom = string.Split(match, ":")
			local tag = table.remove(boom, 1)
			local key_values = {}
			
			for index, gib in ipairs(boom) do
				local key, value = unpack(string.Split(gib, "="))
				
				key_values[key] = value
			end
			
			build_text(accumulator, text, old_finish, start - 1)
			
			table.insert(accumulator, {
				color = colored and (language_colors[tag] or color_default),
				key_values = next(key_values) and key_values or nil,
				tag = tag,
				text = phrases[tag] or "[>" .. tag .. "<]"
			})
		else build_text(accumulator, text, old_finish, #text) end
	until match == nil
	
	for index, text_data in ipairs(accumulator) do
		local color = text_data.color
		local key_values = text_data.key_values
		local new_text, new_color
		local text = text_data.text
		
		text_data.original = text
		
		if key_values then new_text, new_color = fetch_special_replacement(index, text_data.tag, text, key_values, text_data, accumulator) end
		if color then table.insert(texts, new_color or color) end
		
		table.insert(texts, new_text or text)
	end
	
	return colored and texts or table.concat(texts, "")
end

--retro tag replacement, was not featureful enough
--local function replace_tags(text, phrases) return (string.gsub(text, "%[%:(.-)%]", phrases)) end

--pyrition functions
function PYRITION:LanguageFormat(key, phrases) return phrases and replace_tags(language.GetPhrase(key), phrases) or language.GetPhrase(key) end
function PYRITION:LanguageFormatColor(key, phrases) return phrases and replace_tags(language.GetPhrase(key), phrases, true) or {color_default, language.GetPhrase(key)} end
function PYRITION:LanguageFormatColorTranslated(text, phrases) return phrases and replace_tags(text, phrases, true) or {color_default, text} end
function PYRITION:LanguageFormatTranslated(text, phrases) return phrases and replace_tags(text, phrases) or text end

function PYRITION:PyritionLanguageRegisterColor(color, ...) for index, tag in ipairs{...} do language_colors[tag] = color end end

function PYRITION:PyritionLanguageRegisterOption(option, operation, colored) --options are the media of message delivery
	language_options[option] = operation
	language_options_colored[option] = colored or nil
	
	if CLIENT then return end
	
	self:NetAddEnumeratedString("language_options", option)
end

function PYRITION:PyritionLanguageRegisterKieve(kieve_function, ...) for index, tag in ipairs{...} do language_kieves[tag] = kieve_function end end

--post
PYRITION:GlobalHookCreate("LanguageRegisterColor")
PYRITION:GlobalHookCreate("LanguageRegisterOption")
PYRITION:GlobalHookCreate("LanguageRegisterKieve")

PYRITION:LanguageRegisterColor(color_command, "command")
PYRITION:LanguageRegisterColor(color_misc, "map", "reason", "time")
PYRITION:LanguageRegisterColor(color_player, "executor", "target", "targets")

PYRITION:LanguageRegisterKieve(kieve_executor, "executor")
PYRITION:LanguageRegisterKieve(kieve_targets, "target", "targets")

PYRITION:LanguageRegisterOption("center", function(formatted, key, phrases) LocalPlayer():PrintMessage(HUD_PRINTCENTER, formatted) end)
PYRITION:LanguageRegisterOption("chat", function(formatted_table, key, phrases) chat.AddText(unpack(formatted_table)) end, true)
PYRITION:LanguageRegisterOption("console", function(formatted, key, phrases) MsgC(color_white, formatted, "\n") end)