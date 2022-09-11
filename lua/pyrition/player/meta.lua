--locals
local player_meta = FindMetaTable("Player")
local world = game.GetWorld()

--player meta functions
function player_meta:IsPlayerOrWorld() return self:IsPlayer() or self == world end

--hooks
hook.Add("InitPostEntity", "PyritionPlayerMeta", function() world = game.GetWorld() end)