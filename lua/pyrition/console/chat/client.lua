--local functions
local function build_panel_roster(parent)
	local roster = {}
	
	for index, child in ipairs(parent:GetChildren()) do
		local existing = roster[name]
		local name = child:GetName()
		
		if istable(existing) then table.insert(existing, child)
		elseif ispanel(existing) then roster[name] = {existing, child}
		else roster[name] = child end
	end
	
	return roster
end

local function find_chat()
	local panel = vgui.GetKeyboardFocus()
	
	if IsValid(panel) and panel:GetName() == "ChatInput" then
		local parent_panels = {}
		
		repeat
			parent_panels[panel:GetName()] = panel
			panel = panel:GetParent()
		until not IsValid(panel)
		
		local hacking_panel
		local hud_chat = parent_panels.HudChat
		local view_port = parent_panels.CBaseViewport
		
		do --dragging panel
			for index, child in ipairs(view_port:GetChildren()) do if child.IsPyritionChatHacker then child:Remove() end end
			
			hacking_panel = vgui.Create("DPanel", view_port)
			hacking_panel.HUDChat = hud_chat
			hacking_panel.IsPyritionChatHacker = true
			PYRITION.ConsoleCommandChatHackingPanel = hacking_panel
			view_port.PyritionChatHacker = hacking_panel
			
			hacking_panel:SetPos(0, 0)
			hacking_panel:SetSize(view_port:GetSize())
			hacking_panel:SetZPos(305)
			
			function hacking_panel:FinishChat()
				local frame = self.Frame
				
				hud_chat:SetParent(view_port)
				
				if IsValid(frame) then
					self.Frame = nil
					
					frame:Remove()
				end
				
				self:SetVisible(false)
			end
			
			function hacking_panel:OnMousePressed(code)
				local frame = self.Frame
				
				if IsValid(frame) then hud_chat:MakePopup() end
			end
			
			function hacking_panel:OnRemove()
				PYRITION.ConsoleCommandChatHackingPanel = nil
				view_port.PyritionChatHacker = nil
				
				self:RestoreChat()
			end
			
			function hacking_panel:Paint(width, height) end
			
			function hacking_panel:RestoreChat()
				hud_chat:SetParent(view_port)
				hud_chat:SetPos(22, 618)
				hud_chat:SetSize(720, 270)
			end
			
			function hacking_panel:StartChat(team)
				local frame = self.Frame
				
				self:SetVisible(true)
				self:MakePopup()
				
				do --frame
					local header_color = Color(141, 141, 141, 128)
					local frame = vgui.Create("DFrame", self)
					local frame_paint = frame.Paint
					local frame_think = frame.Think
					frame.ChatHackDragging = false
					self.Frame = frame
					
					local hud_chat_width, hud_chat_height = hud_chat:GetSize()
					
					frame:DockPadding(0, 24, 0, 0)
					frame:SetPos(math.Clamp(hud_chat:GetX(), 0, hacking_panel:GetWide() - hud_chat_width), math.Clamp(hud_chat:GetY() - 24, 0, hacking_panel:GetTall() - hud_chat_height))
					frame:SetSize(hud_chat_width, hud_chat_height + 24)
					frame:SetTitle("Pyrition Chat Hack")
					
					hud_chat:SetParent(frame)
					hud_chat:MakePopup()
					
					function frame:OnRemove()
						hacking_panel.Frame = nil
						
						chat.Close()
						
						hud_chat:SetParent(view_port)
					end
					
					function frame:Paint(width, height)
						--[[local x, y = self:LocalToScreen(0, 0)
						
						render.SetScissorRect(x, y, x + width, y + 24, true)
							frame_paint(self, width, height)
						render.SetScissorRect(0, 0, 0, 0, false)]]
						
						draw.RoundedBox(8, 0, 0, width, 24, header_color)
						
						surface.SetDrawColor(0, 0, 0, 128)
						surface.DrawLine(5, 23, width - 5, 23)
					end
					
					function frame:Think()
						frame_think(self)
						
						local dragging = self.Dragging and true or false
						local x, y = gui.MousePos()
						
						if x ~= 0 or y ~= 0 then hacking_panel.RestoreCursorX, hacking_panel.RestoreCursorY = x, y end
						
						hud_chat:SetPos(self:GetX(), self:GetY() + 24)
						
						--when we finish dragging we need to regain focus
						if dragging ~= self.ChatHackDragging then
							if not dragging then hud_chat:MakePopup() end
							
							self.ChatHackDragging = dragging
						end
					end
				end
				
				if self.RestoreCursorX then input.SetCursorPos(self.RestoreCursorX, self.RestoreCursorY) end
			end
			
			do --button
				local button = vgui.Create("DButton", hacking_panel)
				local button_paint = button.Paint
				button.WasHovered = false
				
				button:SetFont("DermaLarge")
				button:SetPos(0, 0)
				button:SetSize(64, 64)
				button:SetText("X")
				button:SetZPos(32000)
				
				function button:DoClick() hacking_panel:Remove() end
				
				function button:Paint(width, height)
					local hovered = self.Hovered
					
					if hovered then button_paint(self, width, height) end
					
					if hovered ~= self.WasHovered then
						button:SetText(hovered and "X" or "")
						
						self.WasHovered = hovered
					end
				end
			end
			
			hacking_panel:StartChat()
		end
		
		do --hud chat
			local roster = build_panel_roster(hud_chat)
			local filters_button = roster.ChatFiltersButton
			
			filters_button:SetText("Hijacked!")
		end
		
		return hacking_panel
	end
	
	return false
end

--hooks
hook.Remove("Think", "PyritionConsoleChat")

hook.Add("FinishChat", "PyritionConsoleCommandChat", function()
	local hacking_panel = PYRITION.ConsoleCommandChatHackingPanel
	
	if IsValid(hacking_panel) then hacking_panel:FinishChat() end
end)

hook.Add("StartChat", "PyritionConsoleCommandChat", function(team_chat)
	local hacking_panel = PYRITION.ConsoleCommandChatHackingPanel
	
	if IsValid(hacking_panel) then hacking_panel:StartChat(team_chat)
	else
		hook.Add("Think", "PyritionConsoleCommandChat", function()
			--no better way?
			if find_chat() then hook.Remove("Think", "PyritionConsoleCommandChat") end
		end)
	end
end)

--autoreload
if IsValid(PYRITION.ConsoleCommandChatHackingPanel) then
	PYRITION.ConsoleCommandChatHackingPanel:Remove()
	
	PYRITION.ConsoleCommandChatHackingPanel = nil
end