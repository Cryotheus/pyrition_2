--this is for debugging! in the official release we should be using localization files
local forced = {
	--DIS CO NEC TID
	["player.load"] = "[:executor] has joined the game. Last visited [:visit] ago.",
	["player.load.first"] = "[:executor] has joined the game for their first time.",
	["player.load.renamed"] = "[:executor], formerly known as [:name], has joined the game. Last visited [:visit] ago."
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end