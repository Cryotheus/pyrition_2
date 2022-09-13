--questions? contact: Cryotheum#4096 on discord

--settings
--change this to something unique to prevent texture and material collisions
local namespace = "pyrition/"

--locals
local draw_target --properly scoped local function
local redraw_entities = {} --set the player as the key in this table like redraw_entities[player_entity] = true
local redraw_entities_opaque = {} --table of the redraw_entities's opaque entities
local redraw_entities_translucent = {} --table of the redraw_entities's translucent entities
local rendering_target = false --true if we are rendering from inside of the draw_entities functions
local render_target --texture created by the create_screen_target function
local update_translucency --properly scoped local function
local translucent_render = false --if the current render is in the translucent phase

--materials
--same as pp/copy but shouldn't error and it doesn't get touched by screenspace effects
local material_copy = CreateMaterial(namespace .. "render_materials/copy", "UnlitGeneric", {
	["$basetexture"] = "color", --shuts up errors
	["$fbtexture"] = "_rt_FullFrameFB",
	["$ignorez"] = 1,
	["$writez"] = 0,
	["$linearwrite"] = 0,
})

--the material for our render target texture
local render_material = CreateMaterial(namespace .. "render_materials/translucent_players", "UnlitGeneric", {
	["$basetexture"] = "color", --shuts up errors
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1
})

--local functions
local function create_screen_target()
	local height = ScrH()
	local width = ScrW()
	
	--256: no mips flag (we don't need to downscale)
	--32768: render target flag
	render_target = GetRenderTargetEx(
		namespace .. "render_targets/translucent_players_" .. width .. "_" .. height,
		width, height,
		RT_SIZE_FULL_FRAME_BUFFER, --kinda important
		MATERIAL_RT_DEPTH_SHARED, --very important
		33024, --texture flags, not all that important
		0, --render target flags, you should never really need this unless you're doing hdr
		IMAGE_FORMAT_RGBA8888 --8 bits for abledo channels and alpha channel
	)
	
	material_copy:SetTexture("$basetexture", render.GetScreenEffectTexture(0))
	render_material:SetTexture("$basetexture", render_target)
	
	--do a proper full clear of the render target
	--this always needs to be done once to the render target
	do render.PushRenderTarget(render_target)
		cam.Start2D()
			render.Clear(0, 0, 0, 0, true, true)
		cam.End2D()
	end render.PopRenderTarget()
	
	return render_target
end

local function draw_entities(entities)
	--makes a copy of the screen's texture to the effect texture
	render.UpdateScreenEffectTexture()
	
	--then we grab both the effect texture and render target
	local effect_texture = render.GetScreenEffectTexture(0) --basically a screen-sized texture
	local screen = render.GetRenderTarget()
	
	--draw fancy stuff for the render_target texture
	do
		--lets the RenderOverride functions know to allow the DrawModel calls
		rendering_target = true
		
		--copy the current texture on the screen to the effect_texture
		render.CopyRenderTargetToTexture(effect_texture)
		
		--partially clear the texture's (currently the screen) channels
		--we need depth, and we clear stencil below (different than doing it here, I swear)
		render.Clear(0, 0, 0, 0, false, false)
		
		--setup a stencil to record what pixels have been drawn to
		--
		--a pixel whose albedo, alpha, and depth channels are 0 will have their albedo
		--set to the drawn color without any blending or depth comparisons
		--
		--the alpha channel in the is render target is set what should be depth
		--
		--and the depth channel is mysterious, I honestly have no clue if its a copy
		--of what is placed in the alpha channel
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilEnable(true)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilReferenceValue(1)
		render.SetStencilTestMask(0xFF)
		render.SetStencilWriteMask(0xFF)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.ClearStencil()
		
		--everything drawn here will show up in the final texture
		--
		--when drawing players: we need to suppress the PrePlayerDraw call
		--when drawing entities: we need to use RenderOverride for suppression
		--
		--if you don't you may get z fighting or other strangeness
		--the best method for choosing who is drawn is: HASH-MAP-UH!
		for entity in pairs(entities) do
			if entity:IsValid() then
				--only do the drawing if they are in pvs
				if not entity:IsDormant() then entity:DrawModel() end
			else set_entity_redraw(entity) end --remove entity from redraw
		end
		
		--adjust the stencil so we are no longer recording what pixel has been drawn to
		--and instead, only allow that pixel to be drawn if it previously was
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		
		--next we increase the alpha of everything drawn using our stencil
		--we have to do this as the alpha channel has the depth written into it
		--so if we don't, anything close to the camera will be very translucent
		--and only things far away will be opaque
		
		--I'm increasing alpha by drawing an opaque rectangle over the screen
		--since we only want to increase alpha and not albedo or depth,
		--we turn writing to those channels off
		render.OverrideColorWriteEnable(true, false)
		render.OverrideDepthEnable(true, false)
			cam.Start2D()
				surface.SetDrawColor(255, 255, 255)
				surface.DrawRect(0, 0, ScrW(), ScrH())
			cam.End2D()
		render.OverrideColorWriteEnable(false)
		render.OverrideDepthEnable(false)
		
		--done with stencil, turn it off
		render.SetStencilEnable(false)
		
		--hide the entities again
		rendering_target = false	
	end
	
	--restore original scene and store what we have drawn to render_target
	do
		--store what we drew to the second render target and set our render target back to what it was
		render.CopyRenderTargetToTexture(render_target)
		render.SetRenderTarget(screen)
		
		--redraw the existing scene
		render.SetMaterial(material_copy)
		render.DrawScreenQuad()
	end
	
	--draw the render_target texture on the screen
	do render.OverrideDepthEnable(true, false)
		cam.Start2D() --draw the render target
			--should be okay to do here
			draw_target()
		cam.End2D()
	end render.OverrideDepthEnable(false)
end

function draw_target() --draw the material over the screen
	surface.SetDrawColor(255, 255, 255, 128)
	surface.SetMaterial(render_material)
	
	--we draw it like this because of the first row and column seems to not get drawn
	--this hides that issue
	surface.DrawTexturedRect(-1, -1, ScrW() + 1, ScrH() + 1)
	
	--has an edge, so we don't do it like this
	--surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end

function update_translucency(entity)
	if translucent_render then
		redraw_entities_opaque[entity] = nil
		redraw_entities_translucent[entity] = true
	else
		redraw_entities_opaque[entity] = true
		redraw_entities_translucent[entity] = nil
	end
end

local function render_override(self, flags)
	if rendering_target then self:DrawModel(flags)
	else update_translucency(self) end
end

local function set_entity_redraw(entity, enabled)
	enabled = enabled or nil
	redraw_entities[entity] = enabled
	
	if enabled then update_translucency(entity) --until it gets updated
	else
		redraw_entities_opaque[entity] = nil
		redraw_entities_translucent[entity] = nil
	end
	
	if entity:IsPlayer() then return end
	
	--allows the entity to draw only when we are doing the render target shennanigans
	entity.RenderOverride = render_override
end

--globals
PYRITION._GFXRedrawInTranslucentLayer = set_entity_redraw

--hooks
hook.Add("InitPostEntity", "CryotheumsWorkspace", create_screen_target) --recreate render targets to prevent lots of issues
hook.Add("OnScreenSizeChanged", "CryotheumsWorkspace", create_screen_target) --recreate render targets to prevent AA issues

hook.Add("PostDrawOpaqueRenderables", "CryotheumsWorkspace", function(_depth, sky)
	if sky then return end
	
	draw_entities(redraw_entities_opaque)
end)

hook.Add("PostDrawTranslucentRenderables", "CryotheumsWorkspace", function(_depth, sky)
	if sky then return end
	
	draw_entities(redraw_entities_translucent)
end)

hook.Add("PreDrawOpaqueRenderables", "CryotheumsWorkspace", function() translucent_render = false end)
hook.Add("PreDrawTranslucentRenderables", "CryotheumsWorkspace", function() translucent_render = true end)

hook.Add("PrePlayerDraw", "CryotheumsWorkspace", function(ply)
	if rendering_target then return false end
	
	--suppress drawing and update translucency record
	if redraw_entities[ply] then
		update_translucency(ply)
		
		return true
	end
end)

--post
create_screen_target()

--example of enabling it on all players
--for k, v in ipairs(player.GetAll()) do set_entity_redraw(v, true) end