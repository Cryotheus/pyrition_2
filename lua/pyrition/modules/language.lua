--https://wiki.facepunch.com/gmod/language
--gmod dev team (probably just rubat now lol), make the server have the language module! PLEASE!

--pragma once
if language then return end

module("language", package.seeall)

--locals
local color = Color(255, 128, 128)
local escape_characters = {n = string.char(10)}

--we leave the default empty in hopes that the server owner will see the error message and learn that this exists
local sv_gmod_language = CreateConVar("sv_gmod_language", "", FCVAR_ARCHIVE, "Changes language of a Garry's mod server")

--module fields
LanguageCodes = {}
LanguagePhrases = {}

--local functions
local function load_localizations(code)
	if LanguageCodes[code] then
		table.Empty(LanguagePhrases)

		local directory = "resource/localization/" .. code .. "/"
		local files = file.Find(directory .. "*.properties", "GAME")

		for index, file_name in ipairs(files) do
			local file_open = file.Open(directory .. file_name, "r", "GAME")
			local line_read

			repeat
				line_read = file_open:ReadLine()

				if line_read then
					local trimmed = string.TrimLeft(line_read, "%s")

					if not string.StartWith(trimmed, "#") then
						local single = string.TrimRight(trimmed, "\n")
						local start = string.find(single, "=", 1, true)

						if start then
							single = string.gsub(single, "\\.", function(match)
								local character = string.sub(match, 2)

								return escape_characters[character] or character
							end)

							LanguagePhrases[string.sub(single, 1, start - 1)] = string.sub(single, start + 1)
						end
					end
				end
			until not line_read

			file_open:Close()
		end

		return true
	end

	return false
end

local function error_code()
	local code = "en"
	local count = 0
	local total = table.Count(LanguageCodes)

	MsgC(color, "No language specified for the server. Defaulting sv_gmod_language to '" .. code .. "'\n", color_white, "See available language codes below:\n")

	for code in pairs(LanguageCodes) do
		count = count + 1

		MsgC(color_white, code, count < total and ", " or "\n")
	end

	sv_gmod_language:SetString(code)
end

--module functions
function Add(place_holder, full_text) LanguagePhrases[place_holder] = full_text end
function GetPhrase(phrase) return LanguagePhrases[phrase] or phrase end

--convars
cvars.AddChangeCallback("sv_gmod_language", function(_name, _old, new)
	--if they never set up their server's language we want to scream at them so they become wiser
	if not load_localizations(new) then error_code() end
end, "PyritionLanguageLibrary")

--post
do
	local code = sv_gmod_language:GetString()
	local folders = select(2, file.Find("resource/localization/*", "GAME"))

	for index, code in ipairs(folders) do LanguageCodes[code] = true end

	if not LanguageCodes[code] then error_code()
	else load_localizations(code) end
end