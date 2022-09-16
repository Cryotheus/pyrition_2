--locals
local player_meta = FindMetaTable("Player")

--player meta functions
function player_meta:TimeConnected() return PYRITION:PlayerTimeConnected(self) end