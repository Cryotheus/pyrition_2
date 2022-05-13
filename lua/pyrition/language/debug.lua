--this is for debugging! in the official release we should be using localization files
local forced = {
	["player.landing.insufficient"] = "Not enough space.",
	["commands.bring"] = "Teleport a player to yourself.",
	["commands.bring.success"] = "[:player] brought [:targets].",
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end