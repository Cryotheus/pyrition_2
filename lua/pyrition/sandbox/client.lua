--locals
local disable_hud_updates
local enable_hud_updates
local last_armor = 0
local last_armor_time = 0
local local_player = LocalPlayer()
local hud_blocks = {CHudHealth = false}
local update_hud_updates

--convars
local pyrition_sandbox_hud_blocks = CreateClientConVar("pyrition_sandbox_hud_blocks", "1", true, false, language.GetPhrase("pyrition.convars.pyrition_sandbox_hud_blocks"))

--local functions
local function disable_hud_blocks()
	hook.Remove("ContextMenuClosed", "PyritionSandbox", enable_hud_updates)
	hook.Remove("ContextMenuOpened", "PyritionSandbox", disable_hud_updates)
	hook.Remove("HUDShouldDraw", "PyritionSandbox")
	hook.Remove("Think", "PyritionSandbox")
end

function disable_hud_updates()
	hook.Remove("Think", "PyritionSandbox")
	
	hud_blocks = {}
end

local function do_hud_blocks(name) if hud_blocks[name] then return false end end

local function enable_hud_blocks()
	hook.Add("ContextMenuClosed", "PyritionSandbox", enable_hud_updates)
	hook.Add("ContextMenuOpened", "PyritionSandbox", disable_hud_updates)
	hook.Add("HUDShouldDraw", "PyritionSandbox", do_hud_blocks)
	hook.Add("Think", "PyritionSandbox", update_hud_updates)
end
	
function enable_hud_updates() hook.Add("Think", "PyritionSandbox", update_hud_updates) end

function update_hud_updates()
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
cvars.AddChangeCallback("pyrition_sandbox_hud_blocks", function()
	--branchless way of doing it?
	return pyrition_sandbox_hud_blocks:GetBool() and enable_hud_blocks() or disable_hud_blocks()
end, "PyritionSandbox")

--hooks
hook.Add("AddToolMenuCategories", "PyritionSandbox", function()
	spawnmenu.AddToolCategory("Utilities", "Pyrition", "#pyrition")
	spawnmenu.AddToolCategory("Utilities", "PyritionDevelopers", "#pyrition.spawnmenu.categories.developer")
end)

hook.Add("PyritionNetClientInitialized", "PyritionSandbox", function(ply) local_player = ply end)

--post
if pyrition_sandbox_hud_blocks:GetBool() then enable_hud_blocks() end