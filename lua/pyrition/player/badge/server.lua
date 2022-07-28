--locals
local badges = PYRITION.PlayerBadges
local short_steam_id = PYRITION._SignificantDigitSteamID

--pyrition functions
function PYRITION:PlayerBadgeLoaded(ply, class, level)
	--more?
	return self:PlayerBadgeExists(ply, class, level) and self:PlayerBadgeSet(ply, class, level, true)
end

function PYRITION:PlayerBadgeSave(ply, class)
	local badge = ply:PlayerBadgeGet(ply, class)
	local database_name = self.SQLDatabaseName
	local table_name = database_name and "`" .. database_name .. "`.badges" or "pyrition_badges"
	
	if badge then
		local level = badge.Level
		
		self:SQLQuery("insert into " .. table_name .. " (steam_id, class, level) values (" .. short_steam_id(ply) .. ", " .. self:SQLEscape(class) .. ", " .. level .. ") on duplicate key update level = " .. level .. ";", function(result)
			--no more
			print("saved badge in db", result)
		end, function(...) print("failed to save badge in db", ...) end)
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
	
	self:SQLQuery("select * from `" .. table_name .. "` where steam_id = '" .. short_steam_id(ply) .. "';", function(result)
		if not result or table.IsEmpty(result) then return print("there were no badges for", ply) end
		
		PrintTable(istable(result) and result or {"result was type " .. type(result)})
		
		if not istable(result) then return end
		
		for index, entry in ipairs(result) do
			if not IsValid(ply) then return end
			
			self:PlayerBadgeLoaded(ply, entry.class, level)
		end
	end, function(...) print("result erred", ...) end)
end

function PYRITION:PlayerBadgesSave(ply)
	self:SQLBegin()
	
	for class, level in pairs(badges[ply]) do self:PlayerBadgeSave(ply, class, true) end
	
	self:SQLCommit()
end

--hooks
hook.Add("PyritionSQLCreateTables", "PyritionPlayerBadge", function(database_name)
	if database_name then return PYRITION:SQLQuery("create table if not exists `" .. database_name .. "`.badges (steam_id varchar(12) not null, class varchar(255) not null, level int unsigned not null, constraint badge_id primary key (steam_id, class));") end
	
	PYRITION:SQLQuery("create table if not exists pyrition_badges (steam_id varchar(12) not null, class varchar(255) not null, level int unsigned not null, primary key (steam_id, class));")
end)