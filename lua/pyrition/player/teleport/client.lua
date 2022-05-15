local teleport_history = PYRITION.PlayerTeleportHistory
local teleport_history_length = PYRITION.PlayerTeleportHistoryLength

--local functions
local function calculate_reverse_index(index, length) return length - index + 1 end

--pyrition functions
function PYRITION:PlayerTeleportRefreshGUI()
	local list_view = self.PlayerTeleportHistoryList
	
	if IsValid(list_view) then list_view:Refresh() end
end

--hooks
hook.Add("AddToolMenuCategories", "PyritionPlayerTeleport", function() spawnmenu.AddToolCategory("Utilities", "Pyrition", "#pyrition") end)

hook.Add("PopulateToolMenu", "PyritionPlayerTeleport", function()
	spawnmenu.AddToolMenuOption("Utilities", "Pyrition", "Teleport", "#pyrition.spawnmenu.categories.user.teleport", "", "", function(form)
		local button
		local list_view
		
		form:ClearControls()
		
		do --button
			button = vgui.Create("DButton", form)
			
			button:Dock(TOP)
			button:SetEnabled(false)
			button:SetText("#pyrition.spawnmenu.categories.user.teleport.button")
			
			function button:DoClick()
				local command = PYRITION:ConsoleCommandGetExisting("return using")
				local index = self.TeleportIndex
				
				if index and command then PYRITION:ConsoleExecute(LocalPlayer(), command, {"^", tostring(index)}) end
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
			PYRITION.PlayerTeleportHistoryList = list_view
			
			list_view:AddColumn("##")
			list_view:AddColumn("#pyrition.spawnmenu.categories.user.teleport.location")
			list_view:Dock(TOP)
			list_view:DockMargin(0, 4, 0, 0)
			list_view:SetHeight(teleport_history_length * 17 + 17)
			list_view:SetMultiSelect(false)
			
			function list_view:DoDoubleClick(index, row_panel) button:DoClick() end
			
			function list_view:OnRowSelected(index, row_panel)
				button.TeleportIndex = index
				
				button:SetEnabled(true)
				button:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.teleport.button.selected", {index = calculate_reverse_index(index, #teleport_history)}))
			end
			
			--function list_view:PerformLayout(width, height) self:SizeToChildren(false, true) end
			
			function list_view:Refresh()
				local button_index = button.TeleportIndex
				local history_length = #teleport_history
				
				self:Clear()
				
				for index, location in ipairs(table.Reverse(teleport_history)) do
					self:AddLine(
						tostring(calculate_reverse_index(index, history_length)),
						math.Round(location.x) .. ", " .. math.Round(location.y) .. ", " .. math.Round(location.z)
					)
				end
				
				if history_length > 0 then
					self:ClearSelection()
					self:SelectItem(self.Sorted[history_length])
				end
			end
			
			list_view:Refresh()
		end
	end)
end)