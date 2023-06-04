--locals
local PANEL = {}

--panel functions
function PANEL:DoClick() self:GetParent():Remove() end

function PANEL:Init()
	button:SetAutoStretchVertical(true)
	button:SetFont("DermaLarge")
	button:SetText("Emergency Exit")
	button:SetTextColor(color_white)
	button:SetZPos(32767)
end

function PANEL:Paint(width, height)
	if self.Hover then
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(255, 0, 0)

		surface.DrawOutlinedRect(0, 0, width, height, 2)
		surface.SetDrawColor(128, 0, 0)
	end
end

--post
derma.DefineControl(
	"PyritionEmergencyExit",
	"DButton with the sole purpose of closing the parent. Used for developing panels. The button is invisible until hovered.",
	PANEL,
	"DButton"
)