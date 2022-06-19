--this is for debugging! in the official release we should be using localization files
local forced = {
	--DIS CO NEC TID
	["spawnmenu.categories.user.map.columns.map"] = "Map",
	["spawnmenu.categories.user.map.columns.votes"] = "Votes",
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end