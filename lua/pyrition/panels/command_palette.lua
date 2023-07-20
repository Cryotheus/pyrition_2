local blur_material = Material("pp/blurscreen")
local gradient_material = Material("gui/gradient")
local PANEL = {}

local render_target = GetRenderTargetEx(
	"pyrition_command_palette/render_target",
	ScrW(), ScrH(),
	RT_SIZE_FULL_FRAME_BUFFER_ROUNDED_UP,
	MATERIAL_RT_DEPTH_SHARED --[[IMPORTANT]],
	0,
	0,
	IMAGE_FORMAT_RGBA8888
)

local render_target_material = CreateMaterial("pyrition_command_palette/material", "UnlitGeneric", {
	["$basetexture"] = render_target:GetName(),
	["$translucent"] = "1"
})

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

	surface.SetDrawColor(0, 0, 0, 224 * fraction)
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
	self.FocusHeight = 0
	self.FocusWidth = 0
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

function PANEL:Paint(width, height)
	local focus_height = self.FocusHeight
	local focus_width = self.FocusWidth
	local gradient_spacing = focus_width * 0.25
	local gradient_width = focus_width * 0.5
	local gradient_y = self.Stage:GetY()

	local gradient_left = (width - focus_width) * 0.5 - gradient_width - gradient_spacing
	local gradient_right = (width + focus_width) * 0.5 + gradient_spacing

	self:DrawBlur(math.min((RealTime() - self.CreationTime) / 0.15, 1))

	render.PushRenderTarget(render_target)
		cam.Start2D()
			render.Clear(0, 0, 0, 0)

			render.SetScissorRect(gradient_left, gradient_y, gradient_right, gradient_y + focus_height, true)
				for index, card in ipairs(self.Cards) do
					if card.ManualPaint then
						card:PaintManual()
					end
				end
			render.SetScissorRect(0, 0, 0, 0, false)

			render.SetWriteDepthToDestAlpha(false)
				render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_MIN)
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(gradient_material)
					surface.DrawTexturedRect(gradient_right, gradient_y, focus_width, focus_height)
					surface.DrawTexturedRectUV(gradient_left, gradient_y, focus_width, focus_height, 1, 0, 0, 1)
				render.OverrideBlend(false)
			render.SetWriteDepthToDestAlpha(true)
		cam.End2D()
	render.PopRenderTarget()

	surface.SetMaterial(render_target_material)
	surface.DrawTexturedRect(0, 0, width, height)
end

function PANEL:PerformLayout(width, height)
	local focus_height = math.max(math.min(480, height), math.ceil(height * 0.45) * 2)
	local focus_width = math.ceil(height / 6 * 2) * 2
	local stage = self.Stage
	self.FocusHeight = focus_height
	self.FocusWidth = focus_width

	for index, card in ipairs(self.Cards) do card:SetWide(focus_width) end

	stage:SetPos((width + focus_width) / 2 - #self.Cards * focus_width, (height - focus_height) / 2)
	stage:SetHeight(focus_height)
	stage:InvalidateLayout(true)
end

function PANEL:PopCard()
	local cards = self.Cards
	local current_card = table.remove(cards)
	local next_card = cards[#cards]

	if current_card then current_card:Remove() end

	if next_card then
		next_card.ManualPaint = nil

		next_card:SetPaintedManually(false)
	end
end

function PANEL:PushCard(class, ...)
	local stage = self.Stage
	local card = vgui.Create(class, stage)
	local cards = self.Cards
	local previous_card = cards[#cards]
	card.CommandPalette = self

	if previous_card then
		previous_card.ManualPaint = true

		previous_card:SetPaintedManually(true)
	end

	card:Dock(LEFT)
	card:SetCardID(tostring(table.insert(cards, card)))
	card:SetDetails(...)

	self:InvalidateLayout(true)
	stage:InvalidateLayout(true)
	card:InvalidateLayout(true)

	card:Focus()

	return card
end

function PANEL:Think() if gui.IsGameUIVisible() then self:Remove() end end

derma.DefineControl("PyritionCommandPalette", "UI used to search for available commands.", PANEL, "EditablePanel")