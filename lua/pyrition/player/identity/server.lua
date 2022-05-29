--locals
local player_storage_players = PYRITION.PlayerStoragePlayers

--pyrition hooks
function PYRITION:PyritionPlayerStorageLoadedIdentity(ply, player_data, success)
	if not player_data.Loaded then player_data.PreviousName = player_data.name end
	
	player_data.Loaded = true
	player_data.name = ply:Name()
	player_data.steam_id_64 = ply:SteamID64()
end

--hooks
hook.Add("player_changename", "PyritionPlayerIdentity", function(data)
	local ply = Player(data.userid)
	
	if IsValid(ply) then
		local player_data = player_storage_players[ply]
		
		if player_data and player_data.Identity then player_data.Identity.name = data.newname end
	end
end)

--post
gameevent.Listen("player_changename")

PYRITION:PlayerStorageRegister("Identity", "identity", 
	{
		Key = "steam_id_64",
		TypeName = "varchar",
		TypeParameters = 17
	},
	
	{
		Key = "name",
		TypeName = "varchar",
		TypeParameters = 32
	}
)