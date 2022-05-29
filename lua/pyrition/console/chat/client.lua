--locals
local color_cursor = Color(217, 217, 217)
local color_hightlight = Color(255, 156, 2)
local color_hint = Color(112, 112, 112)
local color_text = color_white
local on_player_chat = PYRITION._OnPlayerChat

local command_prefixes = {
	["/"] = true,
	["!"] = false
}

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
		
		do --hacking panel
			for index, child in ipairs(view_port:GetChildren()) do if child.IsPyritionChatHacker then child:Remove() end end
			
			hacking_panel = vgui.Create("DPanel", view_port)
			hacking_panel.ChatInputCachedText = ""
			hacking_panel.HUDChat = hud_chat
			hacking_panel.IsPyritionChatHacker = true
			PYRITION.ConsoleCommandChatHackingPanel = hacking_panel
			view_port.PyritionChatHacker = hacking_panel
			
			hacking_panel:SetPos(0, 0)
			hacking_panel:SetSize(view_port:GetSize())
			hacking_panel:SetZPos(305)
			
			function hacking_panel:FinishChat()
				local frame = self.Frame
				self.TeamChatting = nil
				
				self:RestoreChatInput()
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
			
			function hacking_panel:ReplaceChatInput(team_chat, silent_command, starting_text, prefix)
				local chat_input = self.ChatInput
				local chat_input_line = self.ChatInputLine
				local chat_input_replacement = self.ChatInputReplacement
				local frame = self.Frame
				
				if IsValid(chat_input_replacement) then
					chat_input_replacement:Remove()
					
					self.ChatInputReplacement = nil
				end
				
				if IsValid(chat_input) and IsValid(chat_input_line) and IsValid(frame) then
					local chat_input_prompt = self.ChatInputPrompt
					local chat_input_prompt_text = language.GetPhrase(silent_command and "pyrition.chat.run.silent" or "pyrition.chat.run")
					local chat_input_replacement = vgui.Create("EditablePanel", chat_input_line)
					local starting_text = starting_text or ""
					chat_input_replacement.SilentCommand = silent_command
					self.ChatInputReplacement = chat_input_replacement
					
					chat_input_prompt:SetText(chat_input_prompt_text)
					surface.SetFont("ChatFont")
					
					local chat_input_line_width = chat_input_line:GetWide()
					local chat_input_prompt_width = surface.GetTextSize(chat_input_prompt_text) + 4
					
					chat_input_replacement:SetPos(chat_input_prompt_width, chat_input:GetY())
					chat_input_replacement:SetSize(chat_input_line_width - chat_input_prompt_width, chat_input:GetTall())
					chat_input_replacement:SetZPos(chat_input:GetZPos())
					
					chat_input:SetVisible(false)
					
					do --text entry
						local text_entry = vgui.Create("DTextEntry", chat_input_replacement)
						local text_entry_history_update = text_entry.UpdateFromHistory
						
						text_entry:Dock(FILL)
						text_entry:SetFont("ChatFont")
						text_entry:SetPaintBackground(false)
						text_entry:SetCursorColor(color_cursor)
						text_entry:SetHighlightColor(color_hightlight)
						text_entry:SetText(starting_text)
						text_entry:SetTextColor(color_white)
						
						--always want to be at the end when pasting
						text_entry:SetCaretPos(#text_entry:GetText())
						
						function text_entry:GetAutoComplete(text)
							local auto_compeleted = self.AutoCompleted
							
							if auto_compeleted then
								self.Hint = nil
								
								return PYRITION:ConsoleComplete("", text or self.AutoCompleted or self:GetText())
							end
							
							local completions, hint = PYRITION:ConsoleComplete("", text or self.AutoCompleted or self:GetText())
							
							self.Hint = hint
							
							return completions
						end
						
						function text_entry:OnEnter(text)
							if text == "" then return chat.Close() end
							
							local arguments = PYRITION:ConsoleParseArguments(text)
							local arguments_count = #arguments
							local command, depth = PYRITION:ConsoleCommandGet(arguments, true)
							
							if depth == 0 then PYRITION:LanguageQueue(LocalPlayer(), "pyrition.command.unknown")
							else
								local subbed_arguments = {}
								
								for index = depth + 1, arguments_count do table.insert(subbed_arguments, arguments[index]) end
								
								PYRITION:ConsoleExecute(LocalPlayer(), command, subbed_arguments)
							end
							
							chat.Close()
							
							if silent_command then return end
							
							RunConsoleCommand("say", prefix and prefix .. text or text)
						end
						
						function text_entry:OnKeyCode(code)
							if code == KEY_ESCAPE then chat.Close()
							elseif code == KEY_BACKSPACE and self:GetText() == "" then hacking_panel:RestoreChatInput(team_chat, true) end
							
							self.AutoCompleted, self.AutoCompletedPrevious = nil, self.AutoCompleted
						end
						
						function text_entry:OpenAutoComplete(completions)
							self.FirstAutoCompletionTime = nil
							
							if not completions or not completions[1] then return end
							
							local completion_menu = DermaMenu()
							local x, y = self:LocalToScreen(0, self:GetTall())
							
							self.Menu = completion_menu
							
							for index, completion in ipairs(completions) do
								local option = completion_menu:AddOption(completion, function()
									self.AutoCompleted = self.AutoCompleted or self:GetText()
									self.CodeTyped = false
									self.Hint = nil
									
									self:SetText(completion)
									self:SetCaretPos(completion:len())
									self:RequestFocus()
									self:StartThinking(0)
								end)
								
								option:SetTextColor(color_cursor)
							end
							
							completion_menu:Open(x, y, true, self)
							completion_menu:SetMinimumWidth(self:GetWide())
							completion_menu:SetMaxHeight(ScrH() - y - 10)
							completion_menu:SetPos(x, y)
							
							function completion_menu:Paint(width, height)
								surface.SetDrawColor(32, 32, 32)
								surface.DrawRect(0, 0, width, height)
								
								surface.SetDrawColor(72, 72, 72)
								surface.DrawLine(0, 0, width, 0)
								
								surface.SetDrawColor(color_cursor)
								surface.DrawOutlinedRect(1, -1, width - 2, height)
							end
						end
						
						function text_entry:Paint(width, height)
							local hint = self.Hint
							
							surface.SetDrawColor(32, 32, 32)
							surface.DrawRect(0, 0, width, height)
							
							if hint and hint ~= "" then
								local text = self:GetText()
								
								surface.SetTextColor(color_hint)
								surface.SetFont(self:GetFont())
								surface.SetTextPos(3, 0)
								surface.DrawText(string.EndsWith(text, " ") and text .. hint or text .. " " .. hint)
							end
							
							self:DrawTextEntryText(color_text, color_hightlight, color_cursor)
						end
						
						function text_entry:StartThinking(delay)
							local delay = delay or math.min(RealFrameTime() * 2, 0.1)
							self.FirstAutoCompletionTime = RealTime() + delay
							
							function self:Think()
								if RealTime() > self.FirstAutoCompletionTime then
									self:InvalidateLayout(true)
									self:OpenAutoComplete(self:GetAutoComplete())
									
									self.Think = nil
								end
							end
						end
						
						function text_entry:UpdateFromHistory()
							--attempt to recover persistence
							self.AutoCompleted = self.AutoCompleted or self.AutoCompletedPrevious or self:GetText()
							
							--do the internal bull crap then re-open the menu
							text_entry_history_update(self)
							self:OpenAutoComplete(self:GetAutoComplete())
						end
						
						TextEntryLoseFocus()
						text_entry:RequestFocus()
						text_entry:StartThinking()
					end
				end
			end
			
			function hacking_panel:RestoreChat(team_chat)
				hud_chat:SetParent(view_port)
				hud_chat:SetPos(22, 618)
				hud_chat:SetSize(720, 270)
				
				self:RestoreChatInput()
			end
			
			function hacking_panel:RestoreChatInput(team_chat, focus)
				local chat_input = self.ChatInput
				local chat_input_prompt = self.ChatInputPrompt
				local chat_input_replacement = self.ChatInputReplacement
				
				chat_input:SetVisible(true)
				
				if IsValid(chat_input_replacement) then
					chat_input_replacement:Remove()
					
					self.ChatInputReplacement = nil
				end
				
				if focus then
					self:MakePopup()
					hud_chat:MakePopup()
					chat_input:RequestFocus()
					chat_input:SelectAllText()
					chat_input_prompt:SetText(team_chat and "#chat_say_team" or "#chat_say")
				end
			end
			
			function hacking_panel:StartChat(team_chat)
				local frame = self.Frame
				self.TeamChatting = team_chat
				
				if IsValid(frame) then frame:Remove() end
				
				self:SetVisible(true)
				self:MakePopup()
				
				do --frame
					local header_color = Color(141, 141, 141, 128)
					local frame = vgui.Create("DFrame", self)
					local frame_think = frame.Think
					frame.ChatHackDragging = false
					self.Frame = frame
					
					local hud_chat_width, hud_chat_height = hud_chat:GetSize()
					
					frame:DockPadding(0, 24, 0, 0)
					frame:SetPos(math.Clamp(hud_chat:GetX(), 0, hacking_panel:GetWide() - hud_chat_width), math.Clamp(hud_chat:GetY() - 24, 0, hacking_panel:GetTall() - hud_chat_height - 24))
					frame:SetSize(hud_chat_width, hud_chat_height + 24)
					frame:SetTitle("Pyrition Chat Controller")
					
					hud_chat:SetParent(frame)
					hud_chat:MakePopup()
					
					function frame:OnRemove()
						hacking_panel.Frame = nil
						
						chat.Close()
						
						hud_chat:SetParent(view_port)
					end
					
					function frame:Paint(width, height)
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
			
			function hacking_panel:Think()
				local chat_input = self.ChatInput
				
				if IsValid(chat_input) then
					local cached_text = self.ChatInputCachedText
					local text = chat_input:GetText()
					
					if text ~= cached_text then
						
						self.ChatInputCachedText = text
						
						if cached_text == "" then
							local left_text = string.Left(text, 1)
							local silent_command = command_prefixes[left_text]
							
							if silent_command ~= nil then
								chat_input:SetText(left_text)
								self:ReplaceChatInput(self.TeamChatting, silent_command, string.sub(text, 2), left_text)
							end
						end
					end
				end
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
			
			do --hud chat
				local hud_chat_roster = build_panel_roster(hud_chat)
				
				do --chat input line
					local chat_input_line = hud_chat_roster.ChatInputLine
					local chat_input_line_roster = build_panel_roster(chat_input_line)
					hacking_panel.ChatInputLine = chat_input_line
					
					do --chat input
						local chat_input = chat_input_line_roster.ChatInput
						hacking_panel.ChatInput = chat_input
					end
					
					do --chat input prompt
						local chat_input_prompt = chat_input_line_roster.ChatInputPrompt
						hacking_panel.ChatInputPrompt = chat_input_prompt
					end
				end
			end
			
			hacking_panel:StartChat()
		end
		
		return hacking_panel
	end
	
	return false
end

local function on_player_chat_detour(self, ply, message, team_chat, ply_dead, ...)
	local supressed = on_player_chat(self, ply, message, team_chat, ply_dead, ...)
	
	PYRITION:ConsoleChatPosted(ply, message, team_chat, ply_dead, supressed, ...)
	
	return supressed
end

--pyrition hooks
function PYRITION:PyritionConsoleChatPosted(ply, message, team_chat, ply_dead, supressed) end

--hooks
hook.Add("FinishChat", "PyritionConsoleChat", function()
	local hacking_panel = PYRITION.ConsoleCommandChatHackingPanel
	
	if IsValid(hacking_panel) then hacking_panel:FinishChat() end
end)

hook.Add("Initialize", "PyritionConsoleChat", function()
	on_player_chat = PYRITION._OnPlayerChat or GAMEMODE.OnPlayerChat
	GAMEMODE.OnPlayerChat = on_player_chat_detour
	PYRITION._OnPlayerChat = on_player_chat
end)

hook.Add("ShutDown", "PyritionConsoleChat", function()
	--the chat panel will be left behind in weird spots or unclickable if we don't do this
	local hacking_panel = PYRITION.ConsoleCommandChatHackingPanel
	
	if IsValid(hacking_panel) then hacking_panel:Remove() end
end)

hook.Add("StartChat", "PyritionConsoleChat", function(team_chat)
	local hacking_panel = PYRITION.ConsoleCommandChatHackingPanel
	
	if IsValid(hacking_panel) then hacking_panel:StartChat(team_chat)
	else
		hook.Add("Think", "PyritionConsoleChat", function()
			--no better way?
			if find_chat() then hook.Remove("Think", "PyritionConsoleChat") end
		end)
	end
end)

--autoreload
if IsValid(PYRITION.ConsoleCommandChatHackingPanel) then
	PYRITION.ConsoleCommandChatHackingPanel:Remove()
	
	PYRITION.ConsoleCommandChatHackingPanel = nil
end