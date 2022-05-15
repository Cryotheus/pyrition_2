--this is for debugging! in the official release we should be using localization files
local forced = {
	--DIS CO NEC TID
	["commands.noclip"] = "Noclip",
	["commands.noclip.description"] = "Toggle noclip (ghost-like flight) on players.",
	["commands.noclip.disable"] = "Disable Noclip",
	["commands.noclip.disable.description"] = "Disable noclip (ghost-like flight) on players.",
	["commands.noclip.disable.missed"] = "Failed to disable noclip as no target is alive or in noclip.",
	["commands.noclip.disable.success"] = "[:player] disabled noclip on [:targets].",
	["commands.noclip.enable"] = "Enable Noclip",
	["commands.noclip.enable.description"] = "Enable noclip (ghost-like flight) on players.",
	["commands.noclip.enable.missed"] = "Failed to enabled noclip as no target is alive or out of noclip.",
	["commands.noclip.enable.success"] = "[:player] enabled noclip on [:targets].",
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end