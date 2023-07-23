local PANEL = {}

AccessorFunc(PANEL, "EntryPanel", "EntryPanel", FORCE_STRING)

local function entry_clicked(self) self.IndexingParent:Submit(self, self.Value) end

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

function PANEL:OnSubmit(_value) end

function PANEL:SetChoices(choices)
	local entry_panel = self.EntryPanel
	local panels = self.Panels
	local maximum_index = 0
	local scroller = self.Scroller

	for index, pair in ipairs(choices) do
		local panel = panels[index]
		maximum_index = index

		if entry_panel then
			if not panel then
				local panel = vgui.Create(entry_panel)
				panel.DoClick = entry_clicked
				panel.IndexingParent = self

				panel:Dock(TOP)
				panel:PyritionSetFont("PyritionDermaMedium")
				panel:SetValue(pair)
				scroller:AddItem(panel)
			else panel:SetValue(pair) end
		else
			if not panel then
				panel = vgui.Create("DButton", self)
				panel.DoClick = entry_clicked
				panel.IndexingParent = self
				panels[index] = panel

				panel:Dock(TOP)
				panel:PyritionSetFont("PyritionDermaMedium")
				panel:SetAutoStretchVertical(true)
				scroller:AddItem(panel)
			end

			panel.Value = pair[1]

			panel:SetText(pair[2])
		end
	end

	for index = maximum_index + 1, #panels do
		panels[index]:Remove()

		panels[index] = nil
	end

	self:InvalidateLayout(true)
end

function PANEL:Submit(panel, value)
	if not panel then
		panel = self.Panels[1]

		if panel then value = panel.Value
		else return end
	end

	self:OnSubmit(value)
end

derma.DefineControl(
	"PyritionCommandPaletteCardSimpleOptions",
	"Panel with a list of options, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCard"
)