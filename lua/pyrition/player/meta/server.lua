local player_meta = FindMetaTable("Player")
local fl_Player_TimeConnected = PYRITION.PlayerMetaTimeConnected or player_meta.TimeConnected

PYRITION.PlayerMetaTimeConnected = fl_Player_TimeConnected

function player_meta:TimeConnected()
	if self:IsBot() then PYRITION:PlayerTimeConnected(self) end

	return fl_Player_TimeConnected(self)
end