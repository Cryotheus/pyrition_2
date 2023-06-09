local current_map = game.GetMap()
local map_status = PYRITION.MapStatus
local map_votes = PYRITION.MapVotes
local maps = PYRITION.MapList

local function lead_zeros(number, width) return string.rep("0", width - math.floor(math.log10(number))) .. number end

hook.Add("PopulateToolMenu", "PyritionMap", function()
	spawnmenu.AddToolMenuOption("Utilities", "Pyrition", "Map", "#pyrition.spawnmenu.categories.user.map", "", "", function(form)
		local button
		local button_admin
		local check_box
		local image
		local list_view
		local perform_layout = form.PerformLayout

		form:ClearControls()

		function form:PerformLayout(width, height)
			perform_layout(self, width, height)

			--local image = form.MapThumbnail
			local index_column = list_view.IndexColumn
			local maps_column = list_view.MapsColumn
			local votes_column = list_view.VotesColumn
			local votes_column_header = votes_column.Header

			--set font
			surface.SetFont(votes_column_header:GetFont())

			--thumbnail
			image:SetTall(image:GetWide())

			--header widths
			local index_width = surface.GetTextSize(string.rep("0", math.ceil(math.log10(#maps)))) + 16
			local votes_width = surface.GetTextSize(votes_column_header:GetText()) + 8

			index_column:SetFixedWidth(index_width)
			maps_column:SetFixedWidth(math.max(width - index_width - votes_width - 20, 36))
			votes_column:SetFixedWidth(votes_width)
		end

		do --button
			button = form:Button("#pyrition.spawnmenu.categories.user.map.button")
			form.VoteButton = button

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
			form.AdminButton = button_admin

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
			local button = form:Button("#refresh")
			form.RefreshButton = button

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

		do --check box
			check_box = vgui.Create("DCheckBoxLabel")
			form.VisiblityCheckBox = list_view

			check_box:SetChecked(false)
			check_box:SetText("#pyrition.spawnmenu.categories.user.map.check_box")

			function check_box:OnChange() list_view:Refresh() end

			form:AddItem(check_box)
		end

		do --thumbnail
			image = vgui.Create("DImage", form)
			form.MapThumbnail = image

			image:SetMaterial("matsys_regressiontest/background")
			image:SetVisible(false)
		end

		do --list
			list_view = vgui.Create("DListView", form)
			form.MapListView = list_view

			local index_column = list_view:AddColumn("##")
			local maps_column = list_view:AddColumn("#pyrition.spawnmenu.categories.user.map.columns.map")
			local votes_column = list_view:AddColumn("#pyrition.spawnmenu.categories.user.map.columns.votes")

			list_view.IndexColumn = index_column
			list_view.MapsColumn = maps_column
			list_view.VotesColumn = votes_column

			list_view:Dock(TOP)
			list_view:SetMultiSelect(false)

			function list_view:DoDoubleClick() button:DoClick() end

			function list_view:OnRowSelected(_index, row_panel)
				local map = maps[row_panel.MapIndex]
				local material_name = "maps/thumb/" .. map .. ".png"
				button.Map = map
				button_admin.Map = map

				button:SetEnabled(true)
				button:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.map.button.selected", {map = map}))

				button_admin:SetEnabled(true)
				button_admin:SetText(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.user.map.button_admin.selected", {map = map}))

				if file.Exists(material_name, "GAME") then
					image:SetMaterial(material_name)
					image:SetVisible(true)
				else image:SetVisible(false) end
			end

			function list_view:Refresh()
				local maps_length = #maps
				local maps_zeroes = math.floor(math.log10(maps_length))
				local selected_index
				local selected_map = button.Map
				local show_disabled = check_box:GetChecked()

				self:Clear()
				self:SetHeight(math.max(maps_length + 1, 2) * 17)

				for index, map in ipairs(maps) do
					if show_disabled or map_status[map] then
						local votes = map_votes[map]
						local line = self:AddLine(
							lead_zeros(index, maps_zeroes),
							map,
							votes and tostring(votes) or ""
						)

						line.MapIndex = index

						line:SetTooltip("test!")

						if map == selected_map then selected_index = index end
						if map == current_map then for index, label in ipairs(line.Columns) do label:SetFont("DermaDefaultBold") end end
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

		--after list view
		form:AddItem(image)
	end)
end)

net.Receive("pyrition_map", function()
	if net.ReadBool() then
		local change_time = net.ReadFloat()
		local delay = math.Round(change_time - CurTime())
		local map_name = PYRITION:NetReadEnumeratedString("PyritionMap")

		PYRITION.MapChanging = true
		PYRITION.MapChanges = change_time
		PYRITION.MapChangesTo = map_name

		PYRITION:LanguageDisplay("Chat", "pyrition.map.change", {map = map_name, time = delay})

		return
	end

	PYRITION.MapChanging = false
	PYRITION.MapChanges = nil
	PYRITION.MapChangesTo = nil
end)