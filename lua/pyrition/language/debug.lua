--this is for debugging! in the official release we should be using localization files
local forced = {
	
}

for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end