local teleport_history = PYRITION.PlayerTeleportHistory

--pyrition functions
function PYRITION:PlayerTeleportRefreshGUI()
	local list_view = self.PlayerTeleportHistoryList
	
	if IsValid(list_view) then list_view:Refresh() end
end

--hooks
hook.Add("PopulateToolMenu", "PyritionPlayerTeleport", function()
	spawnmenu.AddToolMenuOption("Utilities", "Pyrition", "Teleport", "#pyrition.spawnmenu.categories.user.teleport", "", "", function(form)
		local button
		local list_view
		
		form:ClearControls()
		
		do --button
			button = form:Button("#pyrition.spawnmenu.categories.user.teleport.button")
			
			button:Dock(TOP)
			button:SetEnabled(false)
			
			function button:DoClick()
				local command = PYRITION:ConsoleCommandGetExisting("return using")
				local index = self.TeleportIndex
				
				if index and command then PYRITION:ConsoleExecute(LocalPlayer(), command, {"^", tostring(index)}) end
			end
		end
		
		do --refresh button
			local button = form:Button("#refresh")
			
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
			PYRITION.PlayerTeleportHistoryList = list_view
			
			list_view:AddColumn("##"):SetFixedWidth(16)
			list_view:AddColumn("#pyrition.command")
			list_view:AddColumn("#pyrition.spawnmenu.categories.user.teleport.note")
			list_view:AddColumn("#pyrition.spawnmenu.categories.user.teleport.age")
			list_view:Dock(TOP)
			list_view:SetMultiSelect(false)
			
			function list_view:DoDoubleClick(index, row_panel) button:DoClick() end
			
			function list_view:OnRowSelected(index, row_panel)
				button.TeleportIndex = index
				
				button:SetEnabled(true)
				button:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.teleport.button.selected", {index = tostring(index)}))
			end
			
			function list_view:Refresh()
				local history_length = #teleport_history
				
				self:Clear()
				self:SetHeight(math.max(history_length + 1, 2) * 17)
				
				for index, data in ipairs(teleport_history) do
					local note = data.Note
					local unix = data.Unix
					
					local time_label = self:AddLine(
						tostring(index),
						data.Type,
						IsEntity(note) and note:Name() or note,
						unix
					).Columns[4]
					
					function time_label:Think()
						local text = string.NiceTime(os.time() - unix)
						
						if self.UpdatedText ~= text then
							self.UpdatedText = text
							
							self:SetText(text)
						end
					end
				end
				
				if history_length > 0 then
					self:ClearSelection()
					self:SelectItem(self.Sorted[history_length])
				else
					button:SetEnabled(false)
					button:SetText("#pyrition.spawnmenu.categories.user.teleport.button")
				end
				
				self:SortByColumn(1, true)
			end
			
			list_view:Refresh()
			form:AddItem(list_view)
		end
	end)
end)