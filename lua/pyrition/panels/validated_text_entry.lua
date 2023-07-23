local PANEL = {}

AccessorFunc(PANEL, "InvalidText", "InvalidText", FORCE_STRING)
AccessorFunc(PANEL, "ValidText", "ValidText", FORCE_STRING)

function PANEL:DoValidate(_text) return false end --for override
function PANEL:GetFont() self.TextEntry:GetFont() end
function PANEL:GetText() self.TextEntry:GetText() end

function PANEL:Init()
	do --text entry
		--POST: make this text entry show completions
		local text_entry = vgui.Create("DTextEntry", self)
		self.TextEntry = text_entry
		text_entry.IndexingParent = self

		function text_entry:OnChange() self.IndexingParent:Validate(self:GetText()) end
	end

	do --icon
		local icon = vgui.Create("PyritionMaterialDesignIconScaler", self)
		self.Icon = icon

		icon:SetIcon("help-circle")
		icon:SetTooltip("Start typing to validate the entry.") --LOCALIZE
		icon:SetIconScale(0.9)
	end
end

function PANEL:PerformLayout(width)
	local icon = self.Icon
	local text_entry = self.TextEntry

	icon:SetSize(0, 0)
	self:SizeToChildren(false, true)

	local icon_size = self:GetTall()

	icon:SetSize(icon_size, icon_size)
	text_entry:SetWide(width - icon_size)
	text_entry:SetX(icon_size)
end

function PANEL:SetFont(font) self.TextEntry:SetFont(font) end
function PANEL:SetPlaceholderText(text) self.TextEntry:SetPlaceholderText(text) end
function PANEL:SetText(text) self.TextEntry:SetText(text) end
function PANEL:SetValue(text) self.TextEntry:SetValue(text) end

function PANEL:Validate(text) --manual calls allowed
	local icon = self.Icon

	if self:DoValidate(text) then
		icon:SetIcon("check-circle")
		icon:SetTooltip(self.ValidText) --LOCALIZE
	else
		icon:SetIcon("close-circle")
		icon:SetTooltip(self.InvalidText) --LOCALIZE
	end
end


derma.DefineControl("PyritionValidatedTextEntry", "Panel containing a DTextEntry and an icon indicating validity.", PANEL, "DSizeToContents")