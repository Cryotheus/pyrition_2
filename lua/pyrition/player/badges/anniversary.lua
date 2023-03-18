--locals
local BADGE = {
	DontSave = true,
	Material = "icon16/cake.png",
	Removable = false
}

language.Add("pyrition.badges.anniversary", "Anniversary")
language.Add("pyrition.badges.anniversary.description", "Awarded to players who have been with the server for more than a year.")

--hooks
hook.Add("PyritionPlayerStorageLoadedTime", "PyritionPlayerBadgesAnniversary", function(ply, player_data)
	local first = player_data.first

	if first then PYRITION:PlayerBadgeSet(ply, "anniversary", os.date("!*t", os.time() - first * 86400).year - 1970, true) end
end)

--post
PYRITION:PlayerBadgeRegister("anniversary", BADGE)