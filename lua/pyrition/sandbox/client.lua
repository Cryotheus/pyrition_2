--locals

--pyrition functions

--hooks
hook.Add("AddToolMenuCategories", "PyritionSandbox", function()
	spawnmenu.AddToolCategory("Utilities", "Pyrition", "#pyrition")
	spawnmenu.AddToolCategory("Utilities", "PyritionDevelopers", "#pyrition.spawnmenu.categories.developer")
end)