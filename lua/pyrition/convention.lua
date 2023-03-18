--internal pyrition functions
function PYRITION._GlobalifyName(local_name) --turns some_class_name into SomeClassName
	local global_name = ""

	for index, word in ipairs(string.Split(local_name, "_")) do global_name = global_name .. string.upper(string.Left(word, 1)) .. string.lower(string.sub(word, 2)) end

	return global_name
end

function PYRITION._SignificantDigitSteamID(steam_id)
	if IsEntity(steam_id) then
		if steam_id:IsBot() then return "bot_" .. steam_id:EntIndex() end

		steam_id = steam_id:SteamID()
	end

	return steam_id[9] .. string.sub(steam_id, 11)
end