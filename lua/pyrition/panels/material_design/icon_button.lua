--locals
local PANEL = {IconUpdated = false}

--local tables
local colors = {
	Color(96, 96, 96),
	Color(160, 160, 160),
	Color(208, 208, 208),
	Color(255, 255, 255)
}

--accessor functions
AccessorFunc(PANEL, "Color", "Color", FORCE_COLOR)

--panel functions
function PANEL:Init()
	self:SetColor(Color(255, 255, 255))
	self:SetText("")

	self.GetText = self.GetTooltip
	self.Paint = self.UpdateIconColor
	self.SetText = self.SetTooltip
end

function PANEL:PaintIcon(width, height)
	--this will become the Paint function when the icon is set
	surface.SetDrawColor(self.Color)
	surface.SetMaterial(self.IconMaterial)
	surface.DrawTexturedRectUV(0, 0, width, height, self.IconBeginU, self.IconBeginV, self.IconEndU, self.IconEndV)
end

function PANEL:PerformLayout(width, height)
	if not self.IconName then return end

	local size = math.Round(math.log(math.max(width, height), 2))
	size = math.min(math.Round(size * size), 512)

	if self.IconUpdated or self.IconSize ~= size then
		local material, x, y = PYRITION:GFXMaterialDesignGet(self.IconName, size)

		self.IconBeginU, self.IconBeginV = x / 512, y / 512
		self.IconEndU, self.IconEndV = (x + size) / 512, (y + size) / 512
		self.IconMaterial = material
		self.IconSize = size
		self.IconUpdated = false
		self.Paint = self.PaintIcon
	end
end

function PANEL:SetIcon(icon_name)
	if icon_name ~= self.IconName then
		self.IconMaterial = nil
		self.IconSize = nil
		self.Paint = nil
	end

	self.IconName = icon_name
	self.IconUpdated = true

	self:InvalidateLayout(true)
end

function PANEL:UpdateIconColor()
	local color_index = 2

	if self.Depressed or self:IsSelected() or self:GetToggle() then color_index = 4
	elseif self:GetDisabled() then color_index = 1
	elseif self.Hovered then color_index = 3 end

	if self.ColorIndex ~= color_index then
		self.ColorIndex = color_index

		self:SetColor(colors[color_index])
	end
end

--post
derma.DefineControl("PyritionMaterialDesignIcon", "An icon made with a material design icon vector graphic.", PANEL, "DButton")