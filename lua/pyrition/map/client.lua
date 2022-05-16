local current_map = game.GetMap()
local maps = PYRITION.MapList

--hooks
hook.Add("PopulateToolMenu", "PyritionMap", function()
	spawnmenu.AddToolMenuOption("Utilities", "Pyrition", "Map", "#pyrition.spawnmenu.categories.user.map", "", "", function(form)
		local button
		local button_admin
		local list_view
		
		form:ClearControls()
		
		do --button
			button = form:Button("#pyrition.spawnmenu.categories.user.map.button")
			
			button:Dock(TOP)
			button:SetEnabled(false)
			
			function button:DoClick()
				local command = PYRITION:ConsoleCommandGetExisting("map vote")
				local map = self.Map
				
				if command and map then PYRITION:ConsoleExecute(LocalPlayer(), command, {map}) end
			end
		end
		
		do --admin button
			button_admin = form:Button("#pyrition.spawnmenu.categories.user.map.button")
			
			button_admin:Dock(TOP)
			button_admin:SetEnabled(false)
			button_admin:SetVisible(true)
			
			function button_admin:DoClick()
				local command = PYRITION:ConsoleCommandGetExisting("map")
				local map = self.Map
				
				if command and map then PYRITION:ConsoleExecute(LocalPlayer(), command, {map}) end
			end
		end
		
		do --refresh button
			local button = form:Button("Refresh")
			
			button:Dock(TOP)
			button:SetMaterial("icon16/arrow_refresh.png")
			
			function button:DoClick()
				self.Usable = RealTime() + 1
				
				list_view:Refresh()
				self:SetEnabled(false)
				
				function self:Think()
					if RealTime() > self.Usable then
						self.Think = nil
						
						self:SetEnabled(true)
					end
				end
			end
		end
		
		do --list
			list_view = vgui.Create("DListView", form)
			
			list_view:AddColumn("##"):SetFixedWidth(32)
			list_view:AddColumn("Map")
			list_view:AddColumn("Votes")
			list_view:Dock(TOP)
			list_view:SetMultiSelect(false)
			
			function list_view:DoDoubleClick(index, row_panel) button:DoClick() end
			
			function list_view:OnRowSelected(index, row_panel)
				local map = maps[index]
				button.Map = map
				button_admin.Map = map
				
				button:SetEnabled(true)
				button:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.map.button.selected", {map = map}))
				
				button_admin:SetEnabled(true)
				button_admin:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.map.button_admin.selected", {map = map}))
			end
			
			function list_view:Refresh()
				local maps_length = #maps
				local selected_index
				local selected_map = button.Map
				
				self:Clear()
				self:SetHeight(math.max(maps_length + 1, 2) * 17)
				
				for index, map in ipairs(maps) do
					local line = self:AddLine(tostring(index), map, "0")
					
					if map == selected_map then selected_index = index end
					
					if map == current_map then
						for index, label in ipairs(line.Columns) do
							label:SetFont("DermaDefaultBold")
							label:SetTextColor(Color(16, 112, 32))
						end
					end
				end
				
				--maintain same selection
				if selected_index then
					self:ClearSelection()
					self:SelectItem(self.Sorted[selected_index])
				else
					button:SetEnabled(false)
					button:SetText("#pyrition.spawnmenu.categories.user.map.button")
					
					button_admin:SetEnabled(false)
					button_admin:SetText("#pyrition.spawnmenu.categories.user.map.button")
				end
			end
			
			list_view:Refresh()
			form:AddItem(list_view)
		end
	end)
end)