local PANEL = {}

AccessorFunc(PANEL, "EntryPanel", "EntryPanel", FORCE_STRING)

local function entry_clicked(self) self.IndexingParent:Submit(self, self.Value) end

function PANEL:Init()
	self.Panels = {}

	--self:SetPaintBackgroundEnabled(false)

	do --text entry
		local text_entry = vgui.Create("DTextEntry", self)
		self.TextEntry = text_entry

		text_entry:Dock(TOP)
		text_entry:SetPlaceholderText("Type to search.")
		text_entry:PyritionSetFont("PyritionDermaLarge")
		text_entry:SetMultiline(false)

		surface.SetFont(text_entry:GetFont())
		text_entry:SetTall(select(2, surface.GetTextSize("")) * 1.5)

		function text_entry:OnEnter(value)
			local parent = self:GetParent()

			if parent.OnSubmitEmpty then parent:OnSubmitEmpty()
			else
				parent:SearchInternal(value)
				parent:Submit()
			end
		end

		function text_entry:OnChange() self:GetParent():SearchInternal(self:GetValue()) end
	end

	do
		local scroller = vgui.Create("DScrollPanel", self)
		scroller.Paint = nil
		self.Scroller = scroller

		scroller:Dock(FILL)
		scroller:SetPaintBackgroundEnabled(false)
	end
end

function PANEL:Focus()
	self:SearchInternal()

	hook.Run("OnTextEntryGetFocus", self.TextEntry)
	self.TextEntry:RequestFocus()
end

function PANEL:OnSubmit(_value) end

function PANEL:SearchInternal(needle)
	--results should be a list of tuples
	--the tuple is {value: any, text: string}
	--if you used SetEntryPanel, then SetValue is called on a panel of that type
	--and the tuple (or whatever value you want) is passed in directly
	local entry_panel = self.EntryPanel
	local maximum_index = 0
	local panels = self.Panels
	local results = self:Search(needle or "")
	local scroller = self.Scroller

	for index, pair in ipairs(results) do
		local panel = panels[index]
		maximum_index = index

		if entry_panel then
			if not panel then
				local panel = vgui.Create(entry_panel, self)
				panel.DoClick = entry_clicked
				panel.IndexingParent = self
				panels[index] = panel

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

function PANEL:Search(_needle) return {} end
function PANEL:SetPlaceholderText(text) self.TextEntry:SetPlaceholderText(text) end

function PANEL:Submit(panel, value)
	if not panel then
		panel = self.Panels[1]

		if panel then value = panel.Value
		else return end
	end

	self:OnSubmit(value, panel)
end

derma.DefineControl(
	"PyritionCommandPaletteCardOptions",
	"Panel with searchable options, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCard"
)
