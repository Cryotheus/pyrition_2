local originals = PYRITION.NetDebugOriginals or {}

PYRITION.NetDebugOriginals = originals

hook.Add("PopulateToolMenu", "PyritionNetDebug", function()
	spawnmenu.AddToolMenuOption("Utilities", "PyritionDevelopers", "NetDebug", "#pyrition.spawnmenu.categories.developer.net_debug", "", "", function(form)
		form:ClearControls()

		local category_list = vgui.Create("DCategoryList", form)
		local monitor_category_list
		local monitor_duplex = {}

		form:AddItem(category_list)

		function form:PerformLayout(_width, height) category_list:SetTall(height - 4) end

		do --selection category
			local category = vgui.Create("DCollapsibleCategory", category_list)

			category:SetLabel("Pooled Strings")

			do --contents panel
				local sizer = vgui.Create("DSizeToContents", category)
				category:SetContents(sizer)

				function sizer:Refresh()
					local index = 1
					local network_string = util.NetworkIDToString(index)

					while network_string do
						local checkbox_label = vgui.Create("DCheckBoxLabel", self)
						checkbox_label.NetworkString = network_string

						checkbox_label:Dock(TOP)
						checkbox_label:SetText(network_string)

						function checkbox_label:OnChange(state)
							local network_string = self.NetworkString

							if state then duplex.Insert(monitor_duplex, network_string)
							elseif duplex[network_string] then duplex.Remove(monitor_duplex, network_string) end

							monitor_category_list:Refresh()
						end

						function checkbox_label:OnRemove()
							local network_string = self.NetworkString

							if duplex[network_string] then duplex.Remove(monitor_duplex, network_string) end
						end

						index = index + 1
						network_string = util.NetworkIDToString(index)
					end
				end
			end
		end

		do --monitor category
			local category = vgui.Create("DCollapsibleCategory", category_list)

			category:SetLabel("Monitor")

			do
				monitor_category_list = vgui.Create("DCategoryList", category)

				category:SetContents(monitor_category_list)

				function monitor_category_list:Refresh()
					duplex.Sort(monitor_duplex)
					self:Clear()

					for index, network_string in ipairs(monitor_duplex) do
						--the space is to prevent localization
						local category = self:Add(" " .. network_string)

						--TODO: finish net debug
					end
				end
			end
		end
	end)
end)