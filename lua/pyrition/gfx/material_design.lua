--locals
local render_delay = 0.25
local render_target_size = 512

--globals
PYRITION.GFXMaterialDesignRenderQueue = PYRITION.GFXMaterialDesignRenderQueue or {}
PYRITION.GFXMaterialDesignRenderTargetRepository = PYRITION.GFXMaterialDesignRenderTargetRepository or {}
PYRITION.GFXMaterialDesignRenderTargets = PYRITION.GFXMaterialDesignRenderTargets or {}

--gamemode functions
function PYRITION:GFXMaterialDesignCreate(icon_name, size)
	local first
	local material
	local maximum_icon_length = math.floor(render_target_size / size)
	local maximum_icon_count = maximum_icon_length * maximum_icon_length
	local position_index = 0
	local render_target
	local render_target_index = 1
	local render_targets = self.GFXMaterialDesignRenderTargetRepository[size]
	
	if not render_targets then
		render_targets = {}
		self.GFXMaterialDesignRenderTargetRepository[size] = render_targets
	end
	
	local render_targets_count = #render_targets
	local render_target_details = render_targets[render_targets_count]
	
	if render_target_details and render_target_details.PositionIndex < maximum_icon_count then
		--fetch some data
		material = render_target_details.Material
		position_index = render_target_details.PositionIndex
		render_target = render_target_details.Texture
		
		--increment the position index
		render_target_details.Contains[icon_name] = true
		render_target_details.PositionIndex = position_index + 1
	else
		material = CreateMaterial("pyrition_mdi_materials/" .. size .. "/" .. render_targets_count + 1, "UnlitGeneric", {
			--["$alphatest"] = 1,
			--["$alphatestreference"] = 0.5,
			--["$ignorez"] = 1,
			--["$nolod"] = 1,
			["$basetexture"] = "gui/corner512",
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})
		
		render_target = GetRenderTargetEx(
			"pyrition_mdi_textures/" .. size .. "/" .. render_targets_count,
			render_target_size, render_target_size,
			RT_SIZE_OFFSCREEN,
			MATERIAL_RT_DEPTH_NONE,
			256, --no mips
			0,
			IMAGE_FORMAT_RGBA8888
		)
		
		render_target_details = {
			Contains = {[icon_name] = true},
			Material = material,
			PositionIndex = 1,
			Texture = render_target,
		}
		
		first = true --to clear the target
		render_target_index = render_targets_count + 1
		render_targets[render_targets_count + 1] = render_target_details
		
		--only need to do this once
		material:SetTexture("$basetexture", render_target)
	end
	
	local x = position_index % maximum_icon_length * size
	local y = math.floor(position_index / maximum_icon_length) * size
	local icon_sizes = self.GFXMaterialDesignRenderTargets[icon_name]
	
	if not icon_sizes then
		icon_sizes = {[size] = {render_target_index, x, y}}
		self.GFXMaterialDesignRenderTargets[icon_name] = icon_sizes
	else self.GFXMaterialDesignRenderTargets[icon_name][size] = {render_target_index, x, y} end
	
	table.insert(self.GFXMaterialDesignRenderQueue, {
		First = first,
		Name = icon_name,
		RenderTarget = render_target,
		Size = size,
		X = x,
		Y = y,
	})
	
	self:GFXMaterialDesignRender()
	
	return material, x, y
end

function PYRITION:GFXMaterialDesignGet(icon_name, size)
	local icon_sizes = self.GFXMaterialDesignRenderTargets[icon_name]
	
	if icon_sizes then
		local icon_details = icon_sizes[size]
		
		if icon_details then return self.GFXMaterialDesignRenderTargetRepository[size][icon_details[1]].Material, icon_details[2], icon_details[3] end
	end
	
	return self:GFXMaterialDesignCreate(icon_name, size)
end

function PYRITION:GFXMaterialDesignRender()
	local render_hooks = hook.GetTable().HUDPaint
	
	--don't create the hook if it's already rendering
	if render_hooks and render_hooks.PyritionGFXMaterialDesign then return end
	
	local html_panel
	local html_set = false
	local need_load_wait = false
	local render_queue_index = 1
	local wait
	
	--PreRender wasn't working on all computers, so we're using HUDPaint which seems to work fine
	hook.Add("HUDPaint", "PyritionGFXMaterialDesign", function()
		local real_time = RealTime()
		
		if wait and wait < real_time then return
		else wait = nil end
		
		local queue_info = self.GFXMaterialDesignRenderQueue[render_queue_index]
		
		if html_panel then html_panel:UpdateHTMLTexture() end
		
		if queue_info then
			if html_set then
				--wait for the html to load
				if html_panel:IsLoading() then return end
				
				local html_material = html_panel:GetHTMLMaterial()
				
				if not html_material then return end
				
				if need_load_wait then
					need_load_wait = false
					wait = real_time + render_delay
					
					return
				end
				
				--render the icon onto the render target
				render.PushRenderTarget(queue_info.RenderTarget)
					--if this is the render target's first icon, clear it before rendering
					if queue_info.First then
						--we need both, and in this order
						render.Clear(255, 255, 255, 0, true, true)
						render.Clear(255, 255, 255, 0)
					end
					
					cam.Start2D()
						render.OverrideColorWriteEnable(true, false)
						render.PushFilterMag(TEXFILTER.POINT)
						render.PushFilterMin(TEXFILTER.POINT)
							surface.SetDrawColor(255, 255, 255)
							surface.SetMaterial(html_material)
							
							--for some reason the material is offset by 8 pixels, so we unod that to make sure it's in the right place
							--(I assume this is something to due with the html's style)
							surface.DrawTexturedRect(queue_info.X, queue_info.Y, html_material:Width(), html_material:Height())
							
							--debug
							--surface.DrawOutlinedRect(queue_info.X, queue_info.Y, queue_info.Size, queue_info.Size)
						render.PopFilterMag()
						render.PopFilterMin()
						render.OverrideColorWriteEnable(false)
					cam.End2D()
				render.PopRenderTarget()
				
				html_set = false
				render_queue_index = render_queue_index + 1
				
				html_panel:Remove()
			else --set the html
				--for some *** ****** reason we need to recreate the panel EVERY. SINGLE. TIME.
				--thanks garry
				html_panel = vgui.Create("DHTML")
				html_set = true
				need_load_wait = true
				
				html_panel:SetPaintedManually(true)
				html_panel:SetSize(queue_info.Size, queue_info.Size)
				
				function html_panel:OnRemove() html_panel = nil end
				
				html_panel:OpenURL("https://raw.githubusercontent.com/Templarian/MaterialDesign/master/svg/" .. queue_info.Name .. ".svg")
			end
		else --done with the queue, perform cleanup
			local queue = self.GFXMaterialDesignRenderQueue
			
			for index = 1, render_queue_index - 1 do queue[index] = nil end
			
			hook.Remove("HUDPaint", "PyritionGFXMaterialDesign")
			
			--remove the html panel in case the queue was shortened and we had yet to remove it or something
			if html_panel then html_panel:Remove() end
		end
	end)
end

--commands
concommand.Add("d", function()
	--create a dframe that is 75% of the screen's width and height
	local frame = vgui.Create("DFrame")
	
	frame:SetSize(ScrW() * 0.75, ScrH() * 0.75)
	frame:SetTitle("Material Design Icon Debug")
	
	frame:Center()
	frame:MakePopup()
	
	if false then
		local html = vgui.Create("HTML", frame)
		
		html:SetSize(64, 64)
		html:Center()
		html:OpenURL("https://raw.githubusercontent.com/Templarian/MaterialDesign/master/svg/ab-testing.svg")
	else
		local panel = vgui.Create("Panel", frame)
		
		panel:SetSize(512, 512)
		panel:Center()
		
		PYRITION:GFXMaterialDesignGet("square-off", 64)
		PYRITION:GFXMaterialDesignGet("square-root", 64)
		PYRITION:GFXMaterialDesignGet("square-wave", 64)
		PYRITION:GFXMaterialDesignGet("square-small", 64)
		
		local material, _x, _y = PYRITION:GFXMaterialDesignGet("square", 64)
		
		function panel:Paint(width, height)
			render.PushFilterMag(TEXFILTER.POINT)
			render.PushFilterMin(TEXFILTER.POINT)
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(material)
				surface.DrawTexturedRect(0, 0, width, height)
			render.PopFilterMag()
			render.PopFilterMin()
		end
	end
end)