local PANEL = {}

function PANEL:Init() self:SetEntryPanel("PyritionCommandPaletteCardCommandEntry") end

function PANEL:OnSubmit(panel, command_signature)
	local command_table = PYRITION.CommandRegistry[command_signature]

	if panel.NoCommandArguments then --execute!
	else self:PushCard("PyritionCommandPaletteCardCommand", command_signature, command_table) end
end

function PANEL:SetDetails(command_signatures) self:SetChoices(command_signatures) end

derma.DefineControl(
	"PyritionCommandPaletteCardCommandSignatures",
	"Panel with a list of options, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCardSimpleOptions"
)