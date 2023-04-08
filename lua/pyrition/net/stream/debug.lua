--hooks
hook.Add("PopulateToolMenu", "PyritionNetStreamDebug", function()
	spawnmenu.AddToolMenuOption("Utilities", "PyritionDevelopers", "NetStreamDebug", "#pyrition.spawnmenu.categories.developer.net_stream_debug", "", "", function(form)
		form:ClearControls()

		local category_list = vgui.Create("DCategoryList", form)

		form:AddItem(category_list)

		do --selection category
			
		end

		do --monitor category
			
		end
	end)
end)