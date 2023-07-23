--locals
local PANEL = {}

--local tables
local dock_presets = {
	[BOTTOM] = {0.5, 1},
	[FILL] = {0.5, 0.5},
	[LEFT] = {0, 0.5},
	[NODOCK] = {0.5, 0.5}, --the default
	[RIGHT] = {1, 0.5},
	[TOP] = {0.5, 0}
}

--panel functions
function PANEL:Init()
	self.IconPanel = vgui.Create("PyritionMaterialDesignIcon", self)
	self.IconScale = 0.75
	self.IconX = 0.5
	self.IconY = 0.5
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

--post
derma.DefineControl("PyritionMaterialDesignIconScaler", "Wrapper for PyritionMaterialDesignIcon which lets you easily scale the icon inside.", PANEL, "Panel")