--hooks
hook.Add("AddToolMenuCategories", "PyritionSpawnmenu", function()
	spawnmenu.AddToolCategory("Utilities", "Pyrition", "#pyrition")
	spawnmenu.AddToolCategory("Utilities", "PyritionDevelopers", "#pyrition.spawnmenu.categories.developer")
end)

hook.Add("PopulateToolMenu", "PyritionSpawnmenu", function()
	spawnmenu.AddToolMenuOption("Utilities", "Pyrition", "Option", "#pyrition.spawnmenu.categories.user.options", "", "", function(form)
		form:ClearControls()
		form:CheckBox("#pyrition.convars.pyrition_hud_declutter", "pyrition_hud_declutter")
		form:CheckBox("#pyrition.convars.pyrition_hud_declutter_crosshair", "pyrition_hud_declutter_crosshair")
	end)
end)
