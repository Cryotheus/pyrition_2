--locals
local player_storage_players = PYRITION.PlayerStoragePlayers or {}

--local functions
local function week_lapse(time, player_data)
	local this_week = math.floor(time / 604800) --weeks
	local visit_week = math.floor(player_data.visit_week or 0)
	
	if visit_week then 
		if this_week > visit_week then
			if PYRITION:PlayerTimePassedWeek(ply, player_data.week or 0) then player_data.streak = player_data.streak + 1
			else player_data.streak = 0 end
			
			player_data.visit_week = this_week
			player_data.week = 0
		end
	else
		player_data.streak = 0
		player_data.visit_week = this_week
		player_data.week = 0
	end
end

--pyrition functions
function PYRITION:PyritionPlayerTimeGetTotal(ply)
	local player_data = player_storage_players[ply]
	
	if player_data then
		local time_data = player_data.Time
		
		return time_data.total + ply:TimeConnected() - time_data.LastSessionTime
	end
end

function PYRITION:PyritionPlayerTimeGetSession(ply)
	--todo: make sessions persist between maps
	--also use these sessions for the time storage's record column
	return ply:TimeConnected()
end

--pyrition hooks
function PYRITION:PyritionPlayerStorageLoadedTime(_ply, player_data, _success)
	local time = os.time()
	
	if not player_data.first then
		player_data.first = math.floor(os.time() / 86400) --days
		player_data.record = 0
		player_data.total = 0
	end
	
	week_lapse(time, player_data)
end

function PYRITION:PyritionPlayerStorageSaveTime(ply, player_data)
	local last_connected_time = player_data.LastSessionTime or 0
	local time = os.time()
	local time_connected = ply:TimeConnected()
	local time_difference = time_connected - last_connected_time
	
	player_data.LastSessionTime = time_connected
	player_data.record = math.max(time_connected, player_data.record or 0)
	player_data.total = player_data.total + time_difference
	player_data.visit = time
	player_data.week = player_data.week + time_difference
	
	week_lapse(time, player_data)
end

function PYRITION:PyritionPlayerTimePassedWeek(_ply, week_time)
	--how much time the player spent in the previous week
	--used to determine if a player is a regular
	--we return true if the streak should continue
	if week_time / 3600 > 2.5 then return true end
	
	return false
end

--post
PYRITION:LanguageRegisterColor("misc", "visit")
PYRITION:LanguageRegisterTieve("time", "visit")
PYRITION:PlayerStorageRegister("Time", "time", 
	{ --the unix (day) of when the player first visited
		Key = "first",
		TypeName = "smallint",
		Unsigned = true
	},
	
	{ --the longest session in seconds
		Key = "record",
		TypeName = "int",
		Unsigned = true
	},
	
	{ --the amount of weeks in a row reasonably played
		Key = "streak",
		TypeName = "smallint",
		Unsigned = true
	},
	
	{ --the total play time on the server
		Key = "total",
		TypeName = "int",
		Unsigned = true
	},
	
	{ --the unix of the last time this record saved
		Key = "visit",
		TypeName = "int",
		Unsigned = true
	},
	
	{ --the unix (week) of the last visit
		Key = "visit_week",
		TypeName = "smallint",
		Unsigned = true
	},
	
	{ --the total time played this week
		Key = "week",
		TypeName = "mediumint",
		Unsigned = true
	}
)