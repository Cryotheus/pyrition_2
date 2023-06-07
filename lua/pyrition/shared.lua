--sources
--https://github.com/danielga/gmsv_serversecure/blob/71c584f175f03704d7892c1c0b38c0f351b106ec/includes/modules/serversecure.lua#L5-L29
local blacklisted_bytes = {}
local blacklisted_characters = "\a\b\f\t\n\r\x01\x02\x03\x04\x05\x06\x07\x08\x09"
local sequence = "[" .. blacklisted_characters .. "]"

local unpack = unpack or table.unpack
local string_find = string.find
local table_insert = table.insert
local utf8_char = utf8.char
local utf8_codes = utf8.codes
local utf8_len = utf8.len

local function camel_case_to_snake_case_substitution(upper) return "_" .. string.lower(upper) end
local function power_lerp(fraction, power, alpha, bravo) return Lerp(fraction, alpha ^ power, bravo ^ power) ^ (1 / power) end
local function quadratic_lerp(fraction, alpha, bravo) return Lerp(fraction, alpha ^ 2, bravo ^ 2) ^ 0.5 end
local function snake_case_to_camel_case_substitution(first, remaining) return string.upper(first) .. remaining end

function PYRITION._CamelCaseToSnakeCase(camel_case)
	---ARGUMENTS: string
	---RETURNS: string
	---Converts CamelCase to snake_case.
	return string.sub(string.gsub(camel_case, "(%u)", camel_case_to_snake_case_substitution), 2)
end

function PYRITION._ColorMixLinear(fraction, alpha, bravo)
	local alpha_r, alpha_g, alpha_b, alpha_a = alpha:Unpack()
	local bravo_r, bravo_g, bravo_b, bravo_a = bravo:Unpack()

	return Color(
		Lerp(fraction, alpha_r, bravo_r),
		Lerp(fraction, alpha_g, bravo_g),
		Lerp(fraction, alpha_b, bravo_b),
		Lerp(fraction, alpha_a, bravo_a)
	)
end

function PYRITION._ColorMixPower(fraction, power, alpha, bravo)
	local alpha_r, alpha_g, alpha_b, alpha_a = alpha:Unpack()
	local bravo_r, bravo_g, bravo_b, bravo_a = bravo:Unpack()

	return Color(
		power_lerp(fraction, power, alpha_r, bravo_r),
		power_lerp(fraction, power, alpha_g, bravo_g),
		power_lerp(fraction, power, alpha_b, bravo_b),
		power_lerp(fraction, power, alpha_a, bravo_a)
	)
end

function PYRITION._ColorMix(fraction, alpha, bravo)
	local alpha_r, alpha_g, alpha_b, alpha_a = alpha:Unpack()
	local bravo_r, bravo_g, bravo_b, bravo_a = bravo:Unpack()

	return Color(
		quadratic_lerp(fraction, alpha_r, bravo_r),
		quadratic_lerp(fraction, alpha_g, bravo_g),
		quadratic_lerp(fraction, alpha_b, bravo_b),
		quadratic_lerp(fraction, alpha_a, bravo_a)
	)
end

function PYRITION._ColorToUnsignedInteger(r, g, b, a)
	---ARGUMENTS: Color
	---ARGUMENTS: number, number, number, number=nil
	---RETURNS: number
	---SEE: PYRITION._UnsignedIntegerBytes
	---Converts the given color channels into a 32 bit unsigned integer.
	---Can be given a color object or 3-4 numbers. Alpha will default to 255 if 3 numbers are used.
	---The numbers should be in the range of 0 to 255.
	if g then a = a or 255
	else r, g, b, a = r:Unpack() end

	local digital_color = r * 0x1000000 + g * 0x10000 + b * 0x100 + a

	return digital_color
end

function PYRITION._GradientMap(fraction, map, formulae)
	local break_index
	local maximum
	local minimum = 0

	for index, threshold in ipairs(map) do
		if fraction < threshold then
			break_index = index
			maximum = threshold

			if index > 1 then minimum = map[index - 1] end

			break
		end
	end

	if not break_index then
		break_index = #formulae
		maximum = 1
		minimum = map[#map]
	end

	local range = maximum - minimum

	--we need to provide each formula with a fraction 0-1 instead of 0.2 - 0.6 or whatever
	--I would do math.Remap(fraction, minimum, maximum, 0, 1)
	--but that's bloated and I'm on a diet
	local difference = fraction - minimum
	local scaled_fraction = difference / range

	return formulae[break_index](scaled_fraction)
end

function PYRITION._IPToString(numerical_ip)
	---ARGUMENTS: number "32 bit unsigned integer"
	---RETURNS: string
	---SEE: PYRITION._StringToIP
	return
		bit.band(bit.rshift(numerical_ip, 24), 0xFF) .. "." ..
		bit.band(bit.rshift(numerical_ip, 16), 0xFF) .. "." ..
		bit.band(bit.rshift(numerical_ip, 8), 0xFF) .. "." ..
		bit.band(numerical_ip, 0xFF)
end

function PYRITION._RebuildCamelCase(camel_case, separator)
	---ARGUMENTS: string
	---RETURNS: string
	---Converts CamelCase to snake_case but with a custom $separator.
	return string.sub(string.gsub(camel_case, "(%u)", function(upper) return separator .. string.lower(upper) end), string.len(separator) + 1)
end

function PYRITION._SignificantDigitSteamID(steam_id)
	---ARGUMENTS: string/Player
	---RETURNS: string
	---Trims a Steam ID down into only the significant digits.
	---`STEAM_0:1:72956761` becomes `172956761`.
	---A bot with entity index 4 will return `bot_4`.
	if IsEntity(steam_id) then
		if steam_id:IsBot() then return "bot_" .. steam_id:EntIndex() end

		steam_id = steam_id:SteamID()
	end

	return steam_id[9] .. string.sub(steam_id, 11)
end

function PYRITION._SnakeCaseToCamelCase(snake_case)
	---ARGUMENTS: string
	---RETURNS: string
	---Converts snake_case to CamelCase.
	--necessary parenthesis remove second return
	return (string.gsub(snake_case, "(%a)(%a+)(_?)", snake_case_to_camel_case_substitution))
end

function PYRITION._StringReplaceUnsafe(text)
	---ARGUMENTS: string
	---RETURNS: string
	---Replaces unsafe characters in the string - including line feeds and carriage returns.
	if string_find(text, sequence) then --if there's an illegal character, reconstruct the string without it
		local codes = {}

		for point, code in utf8_codes(text) do
			if blacklisted_bytes[code] then table_insert(codes, 32)
			else table_insert(codes, code) end
		end

		return utf8_char(unpack(codes))
	end

	return text
end

function PYRITION._StringToIP(text)
	---ARGUMENTS: string "IP address"
	---RETURNS: number
	---SEE: PYRITION._IPToString
	local first, second, third, fourth = string.match(text, "^(%d+)%.(%d+)%.(%d+)%.(%d+)")

	if not fourth then return end

	return ((fourth * 0x100 + third) * 0x100 + second) * 0x100 + first
end

function PYRITION._StringUTF8Safe(text, limit)
	---ARGUMENTS: string, number
	---RETURNS: boolean
	---Checks if the string is safe given the specified $limit for string length.
	return utf8_len(text, 1, limit) == utf8_len(text, 1, limit - 1)
end

function PYRITION._UnsignedIntegerBytes(integer)
	---ARGUMENTS: number
	---RETURNS: number, number, number, number
	---Converts a 32 bit unsigned integer into four bytes.
	return
		math.floor(integer / 0x1000000),
		math.floor(integer / 0x10000) % 0x100,
		math.floor(integer / 0x100) % 0x100,
		integer % 0x100
end

hook.Add("InitPostEntity", "Pyrition", function() PYRITION.PastInitPostEntity = true end)

hook.Add("Think", "Pyrition", function()
	PYRITION.PastThink = true

	hook.Remove("Think", "Pyrition")
end)

for index, byte in ipairs{string.byte(blacklisted_characters)} do blacklisted_bytes[byte] = true end