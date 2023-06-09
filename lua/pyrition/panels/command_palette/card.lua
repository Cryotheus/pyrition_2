local PANEL = {}

AccessorFunc(PANEL, "CardID", "CardID", FORCE_STRING)

function PANEL:Focus() end

function PANEL:Init()
	self.CardID = tostring(SysTime())
	self.Paint = nil
end

function PANEL:PushCard(class, ...)
	local command_palette = self.CommandPalette

	if command_palette then return command_palette:PushCard(class, ...) end
end

function PANEL:SetDetails() end

derma.DefineControl("PyritionCommandPaletteCard", "Base panel used for the cards on the PyritionCommandPalette panel.", PANEL, "DPanel")