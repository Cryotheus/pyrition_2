--locals
local BADGE = {
	DontSave = true,
	Material = "icon16/cog.png"
}

language.Add("pyrition.badges.bot", "Bot")
language.Add("pyrition.badges.bot.description", "This player is a bot.")

--badge function
function BADGE:Initialize()
	local ply = self.Player
	
	if ply:IsBot() then return end
	
	PYRITION:PlayerBadgeRemove(ply, "bot")
end

--hooks
hook.Add("PyritionPlayerBadgesLoaded", "PyritionPlayerBadgeBot", function(ply) if ply:IsBot() then PYRITION:PlayerBadgeGive(ply, "bot", nil, true) end end)

--post
PYRITION:PlayerBadgeRegister("bot", BADGE)