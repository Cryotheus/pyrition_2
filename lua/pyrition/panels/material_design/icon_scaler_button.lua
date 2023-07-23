--locals
local PANEL = {}

--local tables
local colors = {
	Color(96, 96, 96),
	Color(160, 160, 160),
	Color(208, 208, 208),
	Color(255, 255, 255)
}

local dock_presets = {
	[BOTTOM] = {0.5, 1},
	[FILL] = {0.5, 0.5},
	[LEFT] = {0, 0.5},
	[NODOCK] = {0.5, 0.5},
	[RIGHT] = {1, 0.5},
	[TOP] = {0.5, 0}
}

--panel functions
function PANEL:Init()
	self:SetText("")

	self.GetText = self.GetTooltip
	self.IconPanel = vgui.Create("PyritionMaterialDesignIcon", self)
	self.IconScale = 0.75
	self.IconX = 0.5
	self.IconY = 0.5
	self.Paint = self.UpdateIconColor
	self.SetText = self.SetTooltip
end

function PANEL:PerformLayout(width, height)
	local icon_panel = self.IconPanel
	local icon_scale = self.IconScale
	local icon_size = icon_scale and icon_scale * math.max(width, height) or self.IconSize

	icon_panel:SetSize(icon_size, icon_size)
	icon_panel:SetPos((width - icon_size) * self.IconX, (height - icon_size) * self.IconY)
end

function PANEL:SetIcon(icon_name) self.IconPanel:SetIcon(icon_name) end

function PANEL:SetIconDock(dock)
	local pair = dock_presets[dock]

	self:SetIconFraction(pair[1], pair[2])
end

function PANEL:SetIconFraction(x, y) self.IconX, self.IconY = x, y end

function PANEL:SetIconScale(scale)
	self.IconScale = scale
	self.IconSize = nil
end

function PANEL:SetIconSize(size)
	self.IconScale = nil
	self.IconSize = size
end

function PANEL:UpdateIconColor()
	local color_index = 2

	if self.Depressed or self:IsSelected() or self:GetToggle() then color_index = 4
	elseif self:GetDisabled() then color_index = 1
	elseif self.Hovered then color_index = 3 end

	if self.ColorIndex ~= color_index then
		self.ColorIndex = color_index

		self.IconPanel:SetColor(colors[color_index])
	end
end

--post
derma.DefineControl("PyritionMaterialDesignIconScalerButton", "Wrapper for PyritionMaterialDesignIcon which lets you easily scale the icon inside. Also functions as a button.", PANEL, "DButton")