--pyrition functions
function PYRITION:CommandOpenPalette()
	if gui.IsGameUIVisible() then self:LanguageDisplay("Console", "pyrition.command.palette.blocked")
	else
		if self.CommandPalette then self.CommandPalette:Remove()
		else vgui.Create("PyritionCommandPalette") end
	end
end

--commands
concommand.Add("pyrition_command_palette", function(ply) if ply:IsValid() then PYRITION:CommandOpenPalette() end end)