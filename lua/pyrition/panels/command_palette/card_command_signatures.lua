local PANEL = {}

function PANEL:Init()
	self.Panels = {}

	self:SetPaintBackgroundEnabled(false)

	do
		local scroller = vgui.Create("DScrollPanel", self)
		scroller.Paint = nil
		self.Scroller = scroller

		scroller:Dock(FILL)
		scroller:SetPaintBackgroundEnabled(false)
	end
end

function PANEL:SetDetails(_command_name, command_signatures)
	local panels = self.Panels
	local scroller = self.Scroller

	for index, command_signature in ipairs(command_signatures) do
		local panel = panels[index]
		local text = command_signature
		maximum_index = index

		if not panel then
			panel = vgui.Create("DButton", self)
			panels[index] = panel

			panel:Dock(TOP)
			panel:SetAutoStretchVertical(true)
			panel:SetFont("Trebuchet24")
			scroller:AddItem(panel)
		end

		panel:SetText(">" .. text .. "<")
	end

	self:InvalidateLayout(true)
end

derma.DefineControl(
	"PyritionCommandPaletteCardCommandSignatures",
	"Panel with a list of ptions, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCard"
)