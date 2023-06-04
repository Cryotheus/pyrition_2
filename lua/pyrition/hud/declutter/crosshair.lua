--convars
local pyrition_hud_declutter_crosshair = CreateClientConVar("pyrition_hud_declutter_crosshair", "1", true, false, language.GetPhrase("pyrition.convars.pyrition_hud_declutter_crosshair"))
local pyrition_hud_declutter_crosshair_delay = CreateClientConVar("pyrition_hud_declutter_crosshair_delay", "2.5", true, false, language.GetPhrase("pyrition.convars.pyrition_hud_declutter_crosshair_delay"), 0.1, 60)

--locals
local last_angle = angle_zero
local last_changed = 0
local last_position = vector_origin
local local_player = LocalPlayer()
local hud_blocks = {CHudCrosshair = false}
local update_blocks
local update_delay = pyrition_hud_declutter_crosshair_delay:GetFloat()

--local functions
local function disable_declutter()
	hook.Remove("HUDShouldDraw", "PyritionHUDDeclutterCrosshair")
	hook.Remove("PostDrawTranslucentRenderables", "PyritionHUDDeclutterCrosshair")
end

local function do_declutter(name) if hud_blocks[name] then return false end end

local function enable_declutter()
	hook.Add("HUDShouldDraw", "PyritionHUDDeclutterCrosshair", do_declutter)
	hook.Add("PostDrawTranslucentRenderables", "PyritionHUDDeclutterCrosshair", update_blocks)
end

function update_blocks()
	local angle = local_player:EyeAngles()
	local position = local_player:EyePos()
	local real_time = RealTime()
	local update = false

	if angle ~= last_angle then
		last_angle = angle
		update = true
	end

	if position ~= last_position then
		last_position = position
		update = true
	end

	if update then last_changed = real_time + update_delay end

	hud_blocks.CHudCrosshair = real_time > last_changed
end

--convars
cvars.AddChangeCallback("pyrition_hud_declutter_crosshair", function()
	if pyrition_hud_declutter_crosshair:GetBool() then return enable_declutter() end

	disable_declutter()
end, "PyritionHUDDeclutterCrosshair")

cvars.AddChangeCallback("pyrition_hud_declutter_crosshair_delay", function() update_delay = pyrition_hud_declutter_crosshair_delay:GetFloat() end, "PyritionHUDDeclutterCrosshair")

--hooks
hook.Add("PyritionNetClientInitialized", "PyritionHUDDeclutterCrosshair", function(ply)
	local_player = ply

	if pyrition_hud_declutter_crosshair:GetBool() then enable_declutter() end
end)

--autoreload
if local_player:IsValid() then hook.GetTable().PyritionNetClientInitialized.PyritionHUDDeclutterCrosshair(local_player) end