local PANEL = {}

function PANEL:Init()
	self.Choices = {}

	self:SetPaintBackgroundEnabled(false)

	do --text entry
		local text_entry = vgui.Create("DTextEntry", self)
		self.TextEntry = text_entry

		text_entry:Dock(TOP)
		text_entry:SetPlaceholderText("Type to search.")
		text_entry:SetFont("DermaLarge")
		text_entry:SetMultiline(false)

		surface.SetFont(text_entry:GetFont())
		text_entry:SetTall(select(2, surface.GetTextSize("")) * 1.5)

		function text_entry:OnChange(value) self:GetParent():SearchInternal(value) end

		function text_entry:OnEnter(value)
			local parent = self:GetParent()

			parent:SearchInternal(value)
			parent:Submit()
		end
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

function PANEL:SearchInternal(needle)
	--results should be a list of tuples
	--the tuple is {id: string, text: string}
	local results = self:Search(needle or "")

	for index, result in ipairs(results) do
		
	end
end

function PANEL:Search(_needle) return {} end
function PANEL:SetPlaceholderText(text) self.TextEntry:SetPlaceholderText(text) end

function PANEL:Submit(choice)
	if not choice then
		choice = self.Choices[1]

		if not choice then return end
	end

	self:OnSubmit(choice)
end

derma.DefineControl(
	"PyritionCommandPaletteCardOptions",
	"Panel with searchable options, used for the PyritionCommandPalette panel.",
	PANEL,
	"PyritionCommandPaletteCard"
)