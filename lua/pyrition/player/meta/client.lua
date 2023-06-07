local player_meta = FindMetaTable("Player")

function player_meta:TimeConnected() return PYRITION:PlayerTimeConnected(self) end