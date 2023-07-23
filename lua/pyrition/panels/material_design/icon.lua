--locals
local PANEL = {IconUpdated = false}

--accessor functions
AccessorFunc(PANEL, "Color", "Color", FORCE_COLOR)

--panel functions
function PANEL:Init()
	self:SetColor(Color(255, 255, 255))
	self:SetMouseInputEnabled(false)
end

function PANEL:PaintIcon(width, height)
	--this will become the Paint function when the icon is set
	surface.SetDrawColor(self.Color)
	surface.SetMaterial(self.IconMaterial)
	surface.DrawTexturedRectUV(0, 0, width, height, self.IconBeginU, self.IconBeginV, self.IconEndU, self.IconEndV)
end

function PANEL:PerformLayout(width, height)
	if not self.IconName then return end

	local size = 2 ^ math.Round(math.log(math.max(width, height), 2))

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

--post
derma.DefineControl("PyritionMaterialDesignIcon", "An icon made with a material design icon vector graphic.", PANEL, "Panel")