--local functions
local function camel_case_to_snake_case_substitution(upper) return "_" .. string.lower(upper) end
local function snake_case_to_camel_case_substitution(first, remaining) return string.upper(first) .. remaining end 

--pyrition functions
function PYRITION._CamelCaseToSnakeCase(camel_case)
	---ARGUMENTS: string
	---RETURNS: string
	---Converts CamelCase to snake_case.
	return string.sub(string.gsub(camel_case, "(%u)", camel_case_to_snake_case_substitution), 2)
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

function PYRITION._RebuildCamelCase(camel_case, separator)
	---ARGUMENTS: string
	---RETURNS: string
	---Converts CamelCase to snake_case but with a custom $separator.
	return string.sub(string.gsub(camel_case, "(%u)", function(upper) return separator .. string.lower(upper) end), string.len(separator) + 1)
end
