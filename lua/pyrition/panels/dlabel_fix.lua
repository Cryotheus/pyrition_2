--issue tracker link: https://github.com/Facepunch/garrysmod-issues/issues/5446
--this script fixes the following native script error:
--	[ERROR] lua/vgui/dlabel.lua:168: attempt to call method 'KeyDown' (a nil value)
--	  1. unknown - lua/vgui/dlabel.lua:168
hook.Add("PyritionVGUIRegister_DLabel", "PyritionPanelsDLabel", function(PANEL)
	function PANEL:OnMousePressed(mouse_code)
		if self:GetDisabled() then return
		elseif mouse_code == MOUSE_LEFT and not dragndrop.IsDragging() and self.m_bDoubleClicking then
			if self.LastClickTime and SysTime() - self.LastClickTime < 0.2 then
				self:DoDoubleClickInternal()
				self:DoDoubleClick()

				return
			end

			self.LastClickTime = SysTime()
		end

		--do not do selections if playing is spawning things while moving
		--if we're selectable and have shift held down then go up the parent until we find a selection canvas and start box selection
		if self:IsSelectable() and mouse_code == MOUSE_LEFT and (input.IsShiftDown() or input.IsControlDown()) then
			local ply = LocalPlayer()

			if not (ply:IsValid() and ply.KeyDown and ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)) then return self:StartBoxSelection() end
		end

		self:MouseCapture(true)

		self.Depressed = true

		self:OnDepressed()
		self:InvalidateLayout(true)

		--tell DragNDrop that we're down, and might start getting dragged
		self:DragMousePress(mouse_code)
	end
end)