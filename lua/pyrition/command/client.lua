--pyrition functions
function PYRITION:CommandOpenPalette()
	if gui.IsGameUIVisible() then self:LanguageDisplay("Console", "pyrition.command.palette.blocked")
	else
		if self.CommandPalette then self.CommandPalette:Remove()
		else vgui.Create("PyritionCommandPalette") end
	end
end

function PYRITION:CommandSend(command_signature, arguments)
	local stream = self:NetStreamModelGet("PyritionCommandExecute")

	print("CommandSend", command_signature, arguments, tostring(stream))

	stream:Write(command_signature, arguments)
end

function PYRITION:HOOK_CommandDownload(name, command_table)
	command_table.Downloaded = true

	self:CommandRegisterFinalization(name, command_table.Signature, command_table)
end

concommand.Add("pyrition_command_palette", function(ply) if ply:IsValid() then PYRITION:CommandOpenPalette() end end)