--locals
local blacklisted_bytes = {}
local blacklisted_characters = "\a\b\f\t\n\r\x01\x02\x03\x04\x05\x06\x07\x08\x09"
local sequence = "[" .. blacklisted_characters .. "]"

--localized functions
local unpack = unpack or table.unpack
local string_find = string.find
local table_insert = table.insert
local utf8_char = utf8.char
local utf8_codes = utf8.codes
local utf8_len = utf8.len

--pyrition functions
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

function PYRITION._StringUTF8Safe(text, limit)
	---ARGUMENTS: string, number
	---RETURNS: boolean
	---Checks if the string is safe given the specified $limit for string length.
	return utf8_len(text, 1, limit) == utf8_len(text, 1, limit - 1)
end

--post
for index, byte in ipairs{string.byte(blacklisted_characters)} do blacklisted_bytes[byte] = true end