--locals
local BADGE = {
	DontSave = true,
	Material = "icon16/cog.png",
	Removable = false
}

language.Add("pyrition.badges.bot", "Bot")
language.Add("pyrition.badges.bot.description", "This player is a bot.")

--badge function
function BADGE:Initialize()
	local ply = self.Player
	
	--only bots should have this badge
	if ply:IsBot() then return end
	
	PYRITION:PlayerBadgeRemove(ply, "bot")
end

--post
PYRITION:PlayerBadgeRegister("bot", BADGE)