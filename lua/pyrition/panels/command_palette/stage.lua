local PANEL = {}

function PANEL:Init()
	--TODO: more for PyritionCommandPaletteStage
end

function PANEL:PerformLayout() self:SizeToChildren(true) end

derma.DefineControl("PyritionCommandPaletteStage", "The horizontally moving part of the PyritionCommandPalette panel.", PANEL, "DSizeToContents")