--locals
--local badges = PYRITION.PlayerBadges
local short_steam_id = PYRITION._SignificantDigitSteamID

--globals
PYRITION.PlayerBadgeLoading = PYRITION.PlayerBadgeLoading or {}

--pyrition functions
function PYRITION:PlayerBadgeLoaded(ply, class, level) return self:PlayerBadgeExists(class) and self:PlayerBadgeSet(ply, class, level, true) end

function PYRITION:PlayerBadgeSave(ply, class)
	local badge = self:PlayerBadgeGet(ply, class)
	local database_name = self.SQLDatabaseName
	local table_name = database_name and "`" .. database_name .. "`.badges" or "pyrition_badges"
	
	if badge then
		local level = badge.Level
		
		self:SQLQuery("insert into " .. table_name .. " (steam_id, class, level) values (" .. short_steam_id(ply) .. ", " .. self:SQLEscape(class) .. ", " .. level .. ") on duplicate key update level = " .. level .. ";")
	else
		self:SQLQuery("delete from " .. table_name .. " where steam_id = " .. short_steam_id(ply) .. " and class = " .. self:SQLEscape(class), function(result)
			--no more
			print("removed badge from db", result)
		end, function(...) print("failed to remove badge from db", ...) end)
	end
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
	end, function() self.PlayerBadgeLoading[ply] = nil end)
end

function PYRITION:PlayerBadgesSave(ply, transaction)
	if not self.PlayerBadges then return end
	if not transaction then self:SQLBegin() end
	
	for class, level in pairs(self.PlayerBadges[ply]) do self:PlayerBadgeSave(ply, class, true) end
	
	if not transaction then self:SQLCommit() end
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
	--TODO: implement the everyone list!
	PYRITION:SQLBegin()
	
	for index, ply in ipairs(everyone) do PYRITION:PlayerBadgesSave(ply, true) end
	
	PYRITION:SQLCommit()
end)