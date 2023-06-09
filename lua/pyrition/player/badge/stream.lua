local MODEL = {}

function MODEL:Initialize()
	if SERVER then
		self.Badges = {}

		self:Send()
	end
end

function MODEL:InitialSync()
	--only make an initial sync if there are badges to sync
	for index, ply in ipairs(PYRITION.NetLoadedPlayers) do
		local badges = PYRITION:PlayerBadgesGet(ply)

		if badges and next(badges) then return true end
	end

	return false
end

function MODEL:Read() while self:ReadBool() do PYRITION:PlayerBadgeSet(self:ReadPlayer(), self:ReadEnumeratedString("PyritionBadge"), self:ReadULong()) end end

function MODEL:Write(_ply, badge)
	--POST: look into rewriting unsent data
	--[[do
		local badges = self.Badges
		local written = badges[badge]

		--we don't need to resync badges we are already preparing to sync
		--if the badge was already sent to the client, we'll have to resend it (oops)
		if written and (self.BytesSent or 0) < written then return end

		badges[badge] = self:Size()
	end]]

	self:WriteBool(true) --signify we have a badge written
	self:WritePlayer(badge.Player) --the owner
	self:WriteEnumeratedString("PyritionBadge", badge.Class) --the badge
	self:WriteULong(badge.Level) --the level
end

function MODEL:WriteInitialSync(target_player)
	for index, ply in ipairs(PYRITION.NetLoadedPlayers) do
		local badges = PYRITION:PlayerBadgesGet(ply)

		if badges then for class, badge in pairs(badges) do self:Write(target_player, badge) end end
	end
end

PYRITION:NetStreamModelRegister("PyritionBadge", CLIENT, MODEL)