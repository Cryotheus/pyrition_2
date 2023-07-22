local PANEL = {}

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

			parent:SearchInternal(value)
			parent:Submit()
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
	--the tuple is {id: string, text: string}
	local choices = self.Panels
	local maximum_index = 0
	local results = self:Search(needle or "")
	local scroller = self.Scroller

	for index, result in ipairs(results) do
		local panel = choices[index]
		local text = result[2]
		maximum_index = index

		if not panel then
			panel = vgui.Create("DButton", self)
			panel.DoClick = entry_clicked
			panel.IndexingParent = self
			choices[index] = panel

			panel:Dock(TOP)
			panel:SetAutoStretchVertical(true)
			panel:SetHeight(100)
			panel:PyritionSetFont("PyritionDermaMedium")
			--panel:SetTextColor(Color(0, 255, 0))
			--panel:SetWrap(true)
			scroller:AddItem(panel)
		end

		panel.Value = result

		panel:SetText(text)
	end

	for index = maximum_index + 1, #choices do
		choices[index]:Remove()

		choices[index] = nil
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

	self:OnSubmit(value)
end

derma.DefineControl(
	"PyritionCommandPaletteCardOptions",
	"Panel with searchable options, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCard"
)
