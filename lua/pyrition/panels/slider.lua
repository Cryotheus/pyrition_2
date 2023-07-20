local default_knob_size = 15
local PANEL = {}

AccessorFunc(PANEL, "Decimals", "Decimals", FORCE_NUMBER)
AccessorFunc(PANEL, "NotchColor", "NotchColor", FORCE_COLOR)
AccessorFunc(PANEL, "NotchCount", "NotchCount", FORCE_NUMBER)
AccessorFunc(PANEL, "ResetValue", "ResetValue", FORCE_NUMBER)
AccessorFunc(PANEL, "Value", "Value", FORCE_NUMBER)

local function knob_paint(self, width, height) derma.SkinHook("Paint", "SliderKnob", self, width, height) end

function PANEL:CalculateNotches(count, width)
	if count == 0 then
		self.Notches = {}

		return
	end

	local count = count or self.NotchCount
	local knob_size_left = self.KnobLeft
	local knob_size_right = self.KnobRight
	local notches = {}
	local width = width or self:GetWide()
	self.Notches = notches

	for index = 0, count do table.insert(notches, math.Remap(index / count, 0, 1, knob_size_left, knob_size_right)) end
end

function PANEL:GetNotchColor() return self.NotchColor or self:GetSkin().colNumSliderNotch end

function PANEL:Init()
	self.Decimals = 0
	self.KnobMargin = 5
	self.KnobSize = default_knob_size
	self.Maximum = 1
	self.Minimum = 0
	self.NotchCount = 5
	self.Notches = {}
	self.ResetValue = 0.5
	self.Value = 0.5

	do --knob
		local knob = vgui.Create("DButton", self)
		local knob_pressed = knob.OnMousePressed
		local knob_released = knob.OnMouseReleased
		knob.IndexingParent = self
		knob.Paint = knob_paint
		self.Knob = knob

		knob:NoClipping(false)
		knob:SetIsToggle(true)
		knob:SetSize(default_knob_size, default_knob_size)
		knob:SetText("")
		knob:SetToggle(false)

		function knob:OnCursorMoved(cursor_x, cursor_y)
			local parent = self.IndexingParent

			parent:OnCursorMoved(parent:ScreenToLocal(self:LocalToScreen(cursor_x, cursor_y)))
		end

		function knob:OnMousePressed(code)
			if self.IndexingParent:OnMousePressed(code) then return true end

			return knob_pressed(self, code)
		end

		function knob:OnMouseReleased(code)
			if self.IndexingParent:OnMouseReleased(code) then return true end

			return knob_released(self, code)
		end
	end

	self:SetHeight(default_knob_size + self.KnobMargin)
end

function PANEL:OnCursorMoved(cursor_x, _cursor_y)
	if self.Dragging or self.Knob.Depressed then
		self:Slide(cursor_x)
	end
end

function PANEL:OnMousePressed(code)
	if not self:IsEnabled() then return true end

	if code == MOUSE_MIDDLE then
		self:Reset()

		return true
	elseif code ~= MOUSE_LEFT then return true end

	local knob = self.Knob
	knob.Depressed = true
	self.Dragging = true

	knob:SetToggle(true)
	self:MouseCapture(true)
	self:OnCursorMoved(self:CursorPos())
	self:SetCursor("hand")
end

function PANEL:OnMouseReleased(code)
	if code == MOUSE_MIDDLE then return true
	elseif code ~= MOUSE_LEFT then return true end

	local knob = self.Knob
	knob.Depressed = false
	knob.Hovered = vgui.GetHoveredPanel() == knob or false
	self.Dragging = false

	knob:SetToggle(false)
	self:MouseCapture(false)
	self:SetCursor("arrow")
end

function PANEL:OnValueChanged(_value) end
function PANEL:OnValueChangedInternal(value) self:OnValueChanged(value) end

function PANEL:OnValueChangedInternalConVar(value)
	--this function replaces self.OnValueChangedInternal
	local con_var = self.ConVar

	--if it's not a lua-created convar, we use RunConsoleCommand instead of ConVar:SetFloat
	if bit.band(con_var:GetFlags(), FCVAR_LUA_CLIENT) == 0 then RunConsoleCommand(con_var:GetName(), tostring(value))
	else con_var:SetFloat(value) end

	self:OnValueChanged(value)
end

function PANEL:Paint(_width, height)
	local clipping = DisableClipping(true)
	local knob_size = self.KnobSize
	local line_y = math.min(knob_size, height)
	local notch_y = line_y - (height - line_y) + 1

	surface.SetDrawColor(self:GetNotchColor())
	surface.DrawLine(self.KnobLeft, line_y, self.KnobRight, line_y)

	for index, notch_x in ipairs(self.Notches) do surface.DrawLine(notch_x, notch_y, notch_x, height) end

	DisableClipping(clipping)
end

function PANEL:PerformLayout(width, height)
	if height ~= self.LastHeight then
		local knob_margin = height * 0.25
		local size = height - knob_margin
		self.KnobMargin = knob_margin
		self.KnobSize = size
		self.LastHeight = height

		self.Knob:SetSize(size, size)
	end

	if width ~= self.LastWidth then
		self.LastWidth = width

		self:UpdateSlide(width)
		self:CalculateNotches(nil, width)
	end
end

function PANEL:Reset(no_callback) self:SetValue(self.ResetValue, no_callback) end

function PANEL:SetConVar(con_var_name)
	local con_var = GetConVar(con_var_name)

	self.ConVar = con_var
	self.OnValueChangedInternal = self.OnValueChangedInternalConVar

	self:SetResetValue(tonumber(con_var:GetDefault()))
	self:SetRange(con_var:GetMin(), con_var:GetMax())
	self:Slide(self:ValueToX(con_var:GetFloat()), true)
end

function PANEL:SetNotchColor(color) self.NotchColor = color end

function PANEL:SetRange(minimum, maximum)
	self.Maximum = maximum
	self.Minimum = minimum

	self:UpdateSlide()
end

function PANEL:Slide(cursor_x, no_callback, width)
	local width = width or self:GetWide()

	local knob_size = self.KnobSize
	local knob_size_left = math.ceil(knob_size * 0.5)
	local knob_size_right = width + knob_size_left - knob_size
	local x = math.Clamp(cursor_x, knob_size_left, knob_size_right)

	local value = self:XToValue(cursor_x, width)
	self.KnobLeft = knob_size_left
	self.KnobRight = knob_size_right
	self.Value = value

	self.Knob:SetPos(x - knob_size_left, 0)

	if no_callback then return end

	self:OnValueChangedInternal(value)
end

function PANEL:SetNotchCount(count)
	self.NotchCount = count

	self:CalculateNotches(count)
end

function PANEL:SetValue(value, no_callback, width)
	local width = width or self:GetWide()
	self.Value = value

	local knob_size = self.KnobSize
	local knob_size_left = math.ceil(knob_size * 0.5)
	local knob_size_right = width + knob_size_left - knob_size
	local x = math.Clamp(self:ValueToX(value, width), knob_size_left, knob_size_right)

	self.KnobLeft = knob_size_left
	self.KnobRight = knob_size_right

	self.Knob:SetPos(x - knob_size_left, 0)

	if no_callback then return end

	self:OnValueChangedInternal(value)
end

function PANEL:UpdateSlide(width) self:SetValue(self:GetValue(), true, width) end

function PANEL:ValueToX(value, width)
	local knob_size = self.KnobSize
	local knob_size_left = math.ceil(knob_size * 0.5)
	local knob_size_right = (width or self:GetWide()) - (knob_size - knob_size_left)
	local maximum = self.Maximum
	local minimum = self.Minimum

	return math.Clamp(
		math.Remap(
			math.Round(value, self.Decimals),
			minimum,
			maximum,
			knob_size_left,
			knob_size_right
		),

		knob_size_left,
		knob_size_right
	)
end

function PANEL:XToValue(x, width)
	local knob_size = self.KnobSize
	local knob_size_left = math.ceil(knob_size * 0.5)
	local knob_size_right = (width or self:GetWide()) - (knob_size - knob_size_left)
	local maximum = self.Maximum
	local minimum = self.Minimum

	return math.Clamp(
		math.Round(
			math.Remap(
				x,
				knob_size_left,
				knob_size_right,
				minimum,
				maximum
			),

			self.Decimals
		),

		minimum,
		maximum
	)
end

derma.DefineControl("PyritionSlider", "Pyrition's slider panel.", PANEL, "DPanel")