--hooks
hook.Add("InitPostEntity", "Pyrition", function() PYRITION.PastInitPostEntity = true end)

hook.Add("Think", "Pyrition", function()
	PYRITION.PastThink = true

	hook.Remove("Think", "Pyrition")
end)