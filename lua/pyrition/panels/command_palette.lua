--locals
local PANEL = {}

--panel functions
function PANEL:FillParent()
	self:SetPos(0, 0)
	self:SetSize(self:GetParent():GetSize())
	self:SetZPos(16384)
end

function PANEL:Init()
	PYRITION.CommandPalette = self

	--TODO: remove emergency exit
	vgui.Create("PyritionEmergencyExit"):SetParent(self)

	self:FillParent()
	self:SetSize()
	self:Think()

	hook.Add("OnScreenSizeChanged", self, self.FillParent)
end

function PANEL:OnKeyCodePressed(key_code) if KEY_ESCAPE || KEY_BACKQUOTE then self:Remove() end end

function PANEL:OnRemove()
	PYRITION.CommandPalette = nil

	hook.Remove("OnScreenSizeChanged", self)
end

function PANEL:Paint(width, height)
	surface.DrawRect(0, 0, width, height)
	surface.SetDrawColor(0, 0, 0, 64)
end

function PANEL:PerformLayout(width, height)
	


end

function PANEL:Think() if gui.IsGameUIVisible() then self:Remove() end end

--post
derma.DefineControl("PyritionCommandPalette", "UI used to search for available commands.", PANEL, "EditablePanel")