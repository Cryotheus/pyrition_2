--locals
local disable_hud_updates
local enable_hud_updates
local last_armor = 0
local last_armor_time = 0
local local_player = LocalPlayer()
local hud_blocks = {CHudHealth = false}
local update_hud_blocks

--convars
local pyrition_hud_declutter = CreateClientConVar("pyrition_hud_declutter", "1", true, false, language.GetPhrase("pyrition.convars.pyrition_hud_declutter"))

--local functions
local function disable_hud_blocks()
	hook.Remove("ContextMenuClosed", "PyritionHUDDeclutterBlocks", enable_hud_updates)
	hook.Remove("ContextMenuOpened", "PyritionHUDDeclutterBlocks", disable_hud_updates)
	hook.Remove("HUDShouldDraw", "PyritionHUDDeclutterBlocks")
	hook.Remove("Think", "PyritionHUDDeclutterBlocks")
end

function disable_hud_updates()
	hook.Remove("Think", "PyritionHUDDeclutterBlocks")
	
	hud_blocks = {}
end

local function do_hud_blocks(name) if hud_blocks[name] then return false end end

local function enable_hud_blocks()
	hook.Add("ContextMenuClosed", "PyritionHUDDeclutterBlocks", enable_hud_updates)
	hook.Add("ContextMenuOpened", "PyritionHUDDeclutterBlocks", disable_hud_updates)
	hook.Add("HUDShouldDraw", "PyritionHUDDeclutterBlocks", do_hud_blocks)
	hook.Add("Think", "PyritionHUDDeclutterBlocks", update_hud_blocks)
end

function enable_hud_updates() hook.Add("Think", "PyritionHUDDeclutterBlocks", update_hud_blocks) end

function update_hud_blocks()
	local armor = local_player:Armor()
	local real_time = RealTime()
	
	if armor ~= last_armor then
		last_armor = armor
		last_armor_time = real_time + 2
	end
	
	if local_player:Health() == local_player:GetMaxHealth() then
		hud_blocks.CHudBattery = real_time > last_armor_time
		hud_blocks.CHudHealth = true
	else
		hud_blocks.CHudBattery = false
		hud_blocks.CHudHealth = false
	end
end

--convars
cvars.AddChangeCallback("pyrition_hud_declutter", function()
	if pyrition_hud_declutter:GetBool() then return enable_hud_blocks() end
	
	disable_hud_blocks()
end, "PyritionHUDDeclutterBlocks")

--hooks
hook.Add("PyritionNetClientInitialized", "PyritionHUDDeclutterBlocks", function(ply)
	local_player = ply
	
	if pyrition_hud_declutter:GetBool() then enable_hud_blocks() end
end)

--autoreload
if local_player:IsValid() then hook.GetTable().PyritionNetClientInitialized.PyritionHUDDeclutterBlocks(local_player) end