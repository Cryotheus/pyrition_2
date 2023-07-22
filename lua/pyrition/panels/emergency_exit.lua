local PANEL = {}

function PANEL:DoClick() self:GetParent():Remove() end

function PANEL:Init()
	self:PyritionSetFont("PyritionDermaLarge")
	self:SetText("EMERGENCY EXIT")
	self:SetZPos(32767)

	local text_width, text_height = self:GetTextSize()
	self:SetSize(text_width * 1.5, text_height * 2)
end

function PANEL:Paint(width, height)
	if self.Hovered then
		self:SetTextColor(color_white)

		surface.SetDrawColor(255, 0, 0)
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, width, height, 2)
	else self:SetTextColor(color_transparent) end
end

derma.DefineControl(
	"PyritionEmergencyExit",
	"DButton with the sole purpose of closing the parent. Used for developing panels. The button is invisible until hovered.",
	PANEL,
	"DButton"
)