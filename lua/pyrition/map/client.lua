local maps = PYRITION.MapList

--hooks

--hooks
hook.Add("PopulateToolMenu", "PyritionPlayerTeleport", function()
	spawnmenu.AddToolMenuOption("Utilities", "Pyrition", "Teleport", "#pyrition.spawnmenu.categories.user.teleport", "", "", function(form)
		local button
		local list_view
		
		form:ClearControls()
		
		do --button
			button = vgui.Create("DButton", form)
			
			button:Dock(TOP)
			button:SetEnabled(false)
			button:SetText("Choose a map")
			
			function button:DoClick()
				local command = PYRITION:ConsoleCommandGetExisting("map")
				local map = self.Map
				
				if command and map then PYRITION:ConsoleExecute(LocalPlayer(), command, {map}) end
			end
		end
		
		do --refresh button
			local button = vgui.Create("DButton", form)
			
			button:Dock(TOP)
			button:SetMaterial("icon16/arrow_refresh.png")
			button:SetText("Refresh")
			
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
			
			list_view:AddColumn("##"):SetFixedWidth(16)
			list_view:AddColumn("Map")
			list_view:Dock(TOP)
			list_view:DockMargin(0, 4, 0, 0)
			list_view:SetMultiSelect(false)
			
			function list_view:DoDoubleClick(index, row_panel) button:DoClick() end
			
			function list_view:OnRowSelected(index, row_panel)
				button.Map = row_panel.Columns[2]
				
				button:SetEnabled(true)
				button:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.map.button.selected", {map = tostring(map)}))
			end
			
			function list_view:Refresh()
				local history_length = #teleport_history
				
				self:Clear()
				self:SetHeight(history_length * 17 + 17)
				
				for index, data in ipairs(maps) do
					self:AddLine(
						tostring(index),
						map
					)
				end
			end
			
			list_view:Refresh()
		end
	end)
end)