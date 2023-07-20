local PANEL = {}

AccessorFunc(PANEL, "CardID", "CardID", FORCE_STRING)

function PANEL:Focus()
	
end

function PANEL:Init()
	
end

function PANEL:SetDetails(command_signature)
	
end

derma.DefineControl("PyritionCommandPaletteCardCommand", "Card used for the PyritionCommandPalette panel.", PANEL, "PyritionCommandPaletteCard")