--this is for debugging! in the official release we should be using localization files
local forced = {
	["spawnmenu.categories.developer"] = "Pyrition (Developers)",
	["spawnmenu.categories.developer.net_enumerations"] = "Networking Enumerations",
	["spawnmenu.categories.developer.net_enumerations.additional"] = "Up to [:difference] additional entries may exist, but they have not yet been received.",
	["spawnmenu.categories.developer.net_enumerations.additional.singular"] = "An additional entry may exist, but it has not yet been received.",
	["spawnmenu.categories.developer.net_enumerations.unaccounted"] = "#[:index] <unaccounted>",
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end