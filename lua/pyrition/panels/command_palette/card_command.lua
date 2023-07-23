local PANEL = {}

AccessorFunc(PANEL, "CardID", "CardID", FORCE_STRING)

function PANEL:Focus()

end

function PANEL:Init()
	local label = vgui.Create("DLabel", self)

	label:SetText("work in progress")
end

function PANEL:SetDetails(command_signature, command_table)
	local command_table = PYRITION.CommandRegistry[command_signature]

	for index, argument_settings in ipairs(command_table.Arguments) do
		
	end
end

derma.DefineControl("PyritionCommandPaletteCardCommand", "Card used for the PyritionCommandPalette panel.", PANEL, "PyritionCommandPaletteCard")