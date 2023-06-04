--locals
--local badges = PYRITION.PlayerBadges
local short_steam_id = PYRITION._SignificantDigitSteamID

--globals
PYRITION.PlayerBadgeLoading = PYRITION.PlayerBadgeLoading or {}

--pyrition functions
function PYRITION:PlayerBadgeLoaded(ply, class, level) return self:PlayerBadgeExists(class) and self:PlayerBadgeGive(ply, class, level, true) end

function PYRITION:PlayerBadgeSave(ply, class)
	local badge = self:PlayerBadgeGet(ply, class)

	if badge.DontSave then return end

	local database_name = self.SQLDatabaseName
	local level = badge.Level
	local table_name = database_name and "`" .. database_name .. "`.`badges`" or "pyrition_badges"

	--update the badge, if the levels is less than 1 we remove it instead
	if level > 0 then self:SQLQuery("insert into " .. table_name .. " (steam_id, class, level) values ('" .. short_steam_id(ply) .. "', " .. self:SQLEscape(class) .. ", " .. level .. ") on duplicate key update level = " .. level .. ";")
	else self:SQLQuery("delete from " .. table_name .. " where steam_id = '" .. short_steam_id(ply) .. "' and class = " .. self:SQLEscape(class)) end
end

function PYRITION:PlayerBadgesLoad(ply)
	local database_name = self.SQLDatabaseName
	local table_name = database_name and database_name .. "`.`badges" or "pyrition_badges"

	self.PlayerBadgeLoading[ply] = true

	self:SQLQuery("select * from `" .. table_name .. "` where steam_id = '" .. short_steam_id(ply) .. "';", function(result)
		if ply:IsValid() and ply:IsConnected() and self.PlayerBadgeLoading[ply] and result then
			--grant the player all the badges from the query
			for index, entry in ipairs(result) do self:PlayerBadgeLoaded(ply, entry.class, entry.level) end
		end

		self.PlayerBadgeLoading[ply] = nil

		hook.Call("PyritionPlayerBadgesLoaded", self, ply)
	end, function() self.PlayerBadgeLoading[ply] = nil end)
end

function PYRITION:PlayerBadgeRevoke(ply, class)
	local badge = self:PlayerBadgeGet(ply, class)

	if badge then
		table.Empty(badge)

		badge.Class = class
		badge.Player = ply
		badge.Level = 0 --we mark this badge for removal

		badge:Sync()
	end
end

function PYRITION:PlayerBadgeSync(ply, badge)
	--POST: use the more optimal NetStreamModelQueue
	if ply == true then
		for index, ply in ipairs(self.NetLoadedPlayers) do self:PlayerBadgeSync(ply, badge) end

		return true
	end

	return self:NetStreamModelGet("Badge", ply)(badge)
end

function PYRITION:PlayerBadgesSave(ply, transaction)
	local player_badges = self.PlayerBadges[ply]

	if not player_badges then return end
	if not transaction then self:SQLBegin() end

	for class, level in pairs(player_badges) do self:PlayerBadgeSave(ply, class, true) end

	if not transaction then self:SQLCommitOrDiscard() end
end

--pyrition hooks
function PYRITION:HOOK_PlayerBadgeLevelChanged(ply, badge, old_level, level, old_tier, tier)
	if old_tier then
		if tier < 1 or tier <= old_tier then return end

		self:LanguageQueue(ply, "[:player:you=Your:possessive=en] [:badge] badge has tiered up to tier [:tier].", {
			badge = badge.Class,
			tier = tostring(tier),
			player = ply,
		})
	else
		if level < 1 or level <= old_level then return end

		self:LanguageQueue(ply, "[:player:you=Your:possessive=en] [:badge] badge has levelled up to level [:level].", {
			badge = badge.Class,
			level = tostring(level),
			player = ply,
		})
	end
end

--hooks
hook.Add("PyritionSQLCreateTables", "PyritionPlayerBadge", function(database_name)
	if database_name then PYRITION:SQLQuery("create table if not exists `" .. database_name .. "`.badges (steam_id varchar(12) not null, class varchar(255) not null, level int unsigned not null, constraint badge_id primary key (steam_id, class));")
	else PYRITION:SQLQuery("create table if not exists pyrition_badges (steam_id varchar(12) not null, class varchar(255) not null, level int unsigned not null, primary key (steam_id, class));") end
end)

hook.Add("PyritionPlayerStorageLoadAll", "PyritionPlayerBadge", function(ply) PYRITION:PlayerBadgesLoad(ply) end)

hook.Add("PyritionPlayerStorageSaveAll", "PyritionPlayerBadge", function(ply, disconnected)
	PYRITION:PlayerBadgesSave(ply)

	if disconnected then PYRITION.PlayerBadges[ply] = nil end
end)

hook.Add("PyritionPlayerStorageSaveEveryone", "PyritionPlayerBadge", function(everyone)
	local transaction = PYRITION:SQLBegin()

	for index, ply in ipairs(everyone) do PYRITION:PlayerBadgesSave(ply, transaction) end

	PYRITION:SQLCommitOrDiscard()
end)