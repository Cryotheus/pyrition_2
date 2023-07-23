local PANEL = {}

function PANEL:GetFont() return self.Label:GetFont() end
function PANEL:GetText() return self.Label:GetText() end
function PANEL:GetValue(...) return self.Slider:GetValue(...) end

function PANEL:Init()
	do --label
		local label = vgui.Create("DLabel", self)
		self.Label = label

		label:SetAutoStretchVertical(true)
		label:SetContentAlignment(4)
		label:SetText("")
		label:SetVisible(false)
		label:SetWide(0)
	end

	do --slider
		local slider = vgui.Create("PyritionSlider", self)
		self.Slider = slider
		slider.IndexingParent = self

		function slider:OnValueChanged(value) self.IndexingParent:OnValueChanged(value) end
	end
end

function PANEL:OnValueChanged(_value) end

function PANEL:PerformLayout(width)
	local label = self.Label

	if self.Text then
		local half_width = width * 0.5
		local label_font = label:GetFont()

		surface.SetFont(label_font)

		local text_width = surface.GetTextSize(label:GetText())

		if text_width > half_width then
			label:SetWrap(true)
			label:SetWide(half_width)
		else
			label:SetWrap(false)
			label:SetWide(text_width)
		end

		self:SizeToChildren(false, true)
	else label:SetWide(0) end

	local label_width = label:GetWide()
	local slider = self.Slider

	slider:SetPos(label_width, 0)
	slider:SetWide(width - label_width)

	self:SizeToChildren(false, true)

	local label_tall = label:GetTall()
	local new_height = self:GetTall()

	if label:GetTall() < new_height then label:SetY((new_height - label_tall) * 0.5)
	else label:SetY(0) end
end

function PANEL:SetConVar(...) return self.Slider:SetConVar(...) end
function PANEL:SetDecimals(...) return self.Slider:SetDecimals(...) end
function PANEL:SetFont(font) self.Label:SetFont(font) end
function PANEL:SetKnobSize(...) return self.Slider:SetKnobSize(...) end
function PANEL:SetNotchCount(...) return self.Slider:SetNotchCount(...) end
function PANEL:SetRange(...) return self.Slider:SetRange(...) end
function PANEL:SetResetValue(...) return self.Slider:SetResetValue(...) end

function PANEL:SetText(text)
	local label = self.Label
	self.Text = text

	if text then
		label:SetText(text)
		label:SetVisible(true)
	else
		label:SetText("")
		label:SetVisible(false)
	end
end

function PANEL:SetValue(...) return self.Slider:SetValue(...) end

derma.DefineControl("PyritionLabeledSlider", "Pyrition's slider panel with an automatically toggling label.", PANEL, "DSizeToContents")

--DEBUG!
concommand.Add("pdp", function()
	local frame = vgui.Create("DFrame")

	frame:SetSizable(true)
	frame:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	frame:SetTitle("Pyrition Panel Test")

	--for index, height in ipairs{20, 32, 64, 128, 256} do
	for index, height in ipairs{20} do
		local slider = vgui.Create("PyritionLabeledSlider", frame)

		slider:Dock(TOP)
		slider:SetRange(0, 100)
		slider:SetResetValue(50)
		slider:SetText("SomeText")
		slider:SetValue(50)

		slider:SetHeight(height)
	end

	frame:Center()
	frame:MakePopup()
end, nil, "tests a panel for pyrition")