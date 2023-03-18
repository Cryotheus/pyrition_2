--globals
PYRITION.PlayerTimeConnections = PYRITION.PlayerTimeConnections or {}

--pyrition functions
function PYRITION:PlayerTimeConnected(ply)
	local player_storages = self.PlayerStoragePlayers[ply]
	local connection_time = player_storages and player_storages.Time and player_storages.Time.SessionStart

	return connection_time and os.time() - connection_time or 0
end

--post
PYRITION:LanguageRegisterColor("misc", "visit")
PYRITION:LanguageRegisterTieve("time", "visit")

PYRITION:PlayerStorageRegisterSyncs("Time", {
	--database fields
	first = "ULong",
	record = "ULong",
	streak = "ULong",
	total = "ULong",
	week = "ULong",

	--custom fields
	LastSessionTime = "ULong",
	SessionStart = "ULong",
})