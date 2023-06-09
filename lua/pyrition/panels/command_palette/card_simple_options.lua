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

function PANEL:SetChoices(choices)
	local panels = self.Panels
	local maximum_index = 0
	local scroller = self.Scroller

	for index, result in ipairs(choices) do
		local panel = panels[index]
		local _id = result[1]
		local text = result[2]
		maximum_index = index

		if not panel then
			panel = vgui.Create("DButton", self)
			panels[index] = panel

			panel:Dock(TOP)
			panel:SetAutoStretchVertical(true)
			panel:SetFont("Trebuchet24")
			scroller:AddItem(panel)
		end

		panel:SetText(text)
	end

	for index = maximum_index + 1, #panels do
		panels[index]:Remove()

		panels[index] = nil
	end

	self:InvalidateLayout(true)
end

derma.DefineControl(
	"PyritionCommandPaletteCardSimpleOptions",
	"Panel with a list of ptions, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCard"
)