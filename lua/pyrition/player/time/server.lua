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

function PYRITION:PlayerTimeGetFirst(ply)
	local player_data = self.PlayerStoragePlayers[ply]

	if player_data then return player_data.Time.first * 86400 end
end

function PYRITION:PlayerTimeGetTotal(ply)
	local player_data = self.PlayerStoragePlayers[ply]

	if player_data then
		local time_data = player_data.Time

		return time_data.total + ply:TimeConnected() - time_data.LastSessionTime
	end
end

function PYRITION:PlayerTimeGetSession(ply)
	--todo: make sessions persist between maps
	--also use these sessions for the time storage's record column
	return ply:TimeConnected()
end

function PYRITION:HOOK_PlayerStorageLoadedTime(ply, player_data)
	local time = os.time()

	--setup custom fields
	if not player_data.LastSessionTime then
		player_data.LastSessionTime = 0
		player_data.SessionStart = time

		--send these two fields to the clients
		self:PlayerStorageSync(true, ply, "Time", "LastSessionTime", "SessionStart")
	end

	--setup table for first time players
	if not player_data.first then
		player_data.first = math.floor(time / 86400) --days
		player_data.record = 0
		player_data.total = 0
	end

	week_lapse(time, player_data)
	self:PlayerStorageSync(true, ply, "Time", "first", "record", "streak", "total", "week")
end

function PYRITION:HOOK_PlayerStorageSaveTime(ply, player_data)
	local last_session_time = player_data.LastSessionTime
	local session_time = ply:TimeConnected()
	local time = os.time()
	local time_difference = session_time - last_session_time

	player_data.LastSessionTime = session_time
	player_data.record = math.max(session_time, player_data.record or 0)
	player_data.total = player_data.total + time_difference
	player_data.visit = time
	player_data.week = player_data.week + time_difference

	week_lapse(time, player_data)
end

function PYRITION:HOOK_PlayerTimePassedWeek(_ply, week_time)
	--how much time the player spent in the previous week
	--used to determine if a player is a regular
	--we return true if the streak should continue
	return week_time / 3600 > 2.5
end

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