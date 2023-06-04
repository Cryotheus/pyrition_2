--pyrition functions
function PYRITION._SignificantDigitSteamID(steam_id)
	---ARGUMENTS: string/Player
	---RETURNS: string
	---Trims a Steam ID down into only the significant parts.
	---`STEAM_0:1:72956761` becomes `172956761`.
	---A bot with entity index 4 will return `bot_4`.
	if IsEntity(steam_id) then
		if steam_id:IsBot() then return "bot_" .. steam_id:EntIndex() end

		steam_id = steam_id:SteamID()
	end

	return steam_id[9] .. string.sub(steam_id, 11)
end

function PYRITION._SnakeCaseToCamelCase(snake_case) --turns some_class_name into SomeClassName
	---ARGUMENTS: string
	---RETURNS: string
	---Converts snake_case to CamelCase.
	local camel_case = ""

	for index, word in ipairs(string.Split(snake_case, "_")) do
		camel_case = camel_case .. string.upper(string.Left(word, 1)) .. string.lower(string.sub(word, 2))
	end

	return camel_case
end
