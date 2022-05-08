--this is for debugging! in the official release we should be using localization files
local forced = {
	["commands.unknown"] = "Uknown command.",
	
	["commands.heal"] = "Heals to full health, extinguishes burning players, and resurrects dead players. Will also recharge armor if armor is present.",
	["commands.heal.success"] = "[:player] healed [:targets].",
	
	["commands.health.empty"] = "The first argument must be a number or player.",
	["commands.health.fail"] = "Invalid quantity.",
	["commands.health.missed"] = "No living targets to adjust.",
	["commands.health.success"] = "[:player] modified the health of [:targets].",
	
	["commands.kick"] = "Disconnect a player from the server.",
	["commands.kick.explicable"] = "[:player] kicked [:target] for [:reason].",
	["commands.kick.inexplicable"] = "[:player] kicked [:target].",
	["commands.kick.multiple.explicable"] = "[:player] kicked [:target] for [:reason].",
	["commands.kick.multiple.inexplicable"] = "[:player] kicked [:target].",
	
	["list"] = "[:items], and [:last_item]",
	["list.duo"] = "[:alpha] and [:bravo]",
	["list.everything"] = "everything",
	["list.nothing"] = "nothing",
	["list.seperator"] = ", ",
	
	["player.find.invalid"] = "No valid targets.",
	["player.find.oversized"] = "Too many targets discovered.",
	["player.find.targetless"] = "You must specify a target.",
	
	["player.list"] = "[:names], and [:last_name]",
	["player.list.duo"] = "[:alpha] and [:bravo]",
	["player.list.everyone"] = "everyone",
	["player.list.nobody"] = "nobody",
	["player.list.seperator"] = ", ",
}

--post
for key, phrase in pairs(forced) do language.Add("pyrition." .. key, phrase) end