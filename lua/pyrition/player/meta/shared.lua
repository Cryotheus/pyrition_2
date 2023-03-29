--locals
local baseclass_Get = baseclass.Get
local player_manager_GetPlayerClass = player_manager.GetPlayerClass
local player_meta = FindMetaTable("Player")
local world = game.GetWorld()

--player meta functions
function player_meta:GetPlayerClass() return player_manager_GetPlayerClass(self) end

function player_meta:GetPlayerClassNWField(field, field_type)
	local class_table = baseclass_Get(player_manager_GetPlayerClass(self))
	local get_network_field = class_table.GetNetworkField

	return get_network_field and get_network_field(class_table, field, field_type)
end

function player_meta:GetPlayerClassTable() return baseclass_Get(player_manager_GetPlayerClass(self)) end
function player_meta:IsPlayerOrWorld() return self:IsPlayer() or self == world end

--hooks
hook.Add("InitPostEntity", "PyritionPlayerMeta", function() world = game.GetWorld() end)