local blur_material = Material("pp/blurscreen")
local PANEL = {}

function PANEL:DrawBlur(fraction)
	local clipping = DisableClipping(true)
	local x, y = self:LocalToScreen(0, 0)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(blur_material)

	for third = 0.33, 1, 0.33 do
		blur_material:SetFloat("$blur", fraction * 5 * third)
		blur_material:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
	end

	surface.SetDrawColor(0, 0, 0, 192 * fraction)
	surface.DrawRect(-x, -y, ScrW(), ScrH())

	DisableClipping(clipping)
end

function PANEL:FillParent()
	self:SetPos(0, 0)
	self:SetSize(self:GetParent():GetSize())
	self:SetZPos(16384 / 2)
end

function PANEL:Init()
	local stage = vgui.Create("PyritionCommandPaletteStage", self)

	PYRITION.CommandPalette = self
	self.Cards = {}
	self.CreationTime = RealTime()
	self.Stage = stage

	self:FillParent()
	self:SetFocusTopLevel(true)
	self:SetKeyboardInputEnabled(true)
	self:SetMouseInputEnabled(true)
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:MakePopup()
	self:DoModal()

	hook.Add("OnScreenSizeChanged", self, self.FillParent)
	self:Think()
	vgui.Create("PyritionEmergencyExit"):SetParent(self) --TODO: remove emergency exit

	self:PushCard("PyritionCommandPaletteCardCommands")
end

function PANEL:OnKeyCodePressed(key_code)
	if key_code == KEY_ESCAPE or key_code == KEY_BACKQUOTE then
		self:Remove()
	end
end

function PANEL:OnRemove()
	PYRITION.CommandPalette = nil

	hook.Remove("OnScreenSizeChanged", self)
end

function PANEL:Paint(_width, _height)
	--surface.SetDrawColor(0, 0, 0, 96)
	--surface.DrawRect(0, 0, width, height)
	self:DrawBlur(math.min((RealTime() - self.CreationTime) / 0.15, 1))
end

function PANEL:PerformLayout(width, height)
	local focus_height = math.max(math.min(480, height), math.ceil(height * 0.45) * 2)
	local focus_width = math.ceil(height / 6 * 2) * 2
	local stage = self.Stage

	for index, card in ipairs(self.Cards) do card:SetWide(focus_width) end

	stage:SetPos((width + focus_width) / 2 - #self.Cards * focus_width, (height - focus_height) / 2)
	stage:SetHeight(focus_height)
	stage:InvalidateLayout(true)
end

function PANEL:PushCard(class, ...)
	local stage = self.Stage
	local card = vgui.Create(class, stage)

	card:Dock(LEFT)
	card:SetCardID(tostring(table.insert(self.Cards, card)))
	card:SetDetails(...)

	self:InvalidateLayout(true)
	stage:InvalidateLayout(true)
	card:InvalidateLayout(true)

	card:Focus()
end

function PANEL:Think() if gui.IsGameUIVisible() then self:Remove() end end

derma.DefineControl("PyritionCommandPalette", "UI used to search for available commands.", PANEL, "EditablePanel")