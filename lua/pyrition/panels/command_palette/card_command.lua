local PANEL = {}

AccessorFunc(PANEL, "CardID", "CardID", FORCE_STRING)

function PANEL:Focus()

end

function PANEL:Init()
	self.HintPanels = {}
	self.Panels = {}

	do --header label
		local label = vgui.Create("DLabel", self)
		self.Label = label

		label:Dock(TOP)
		label:PyritionSetFont("PyritionDermaLarge")
		label:SetAutoStretchVertical(true)
		label:SetContentAlignment(5)
	end

	do
		local scroller = vgui.Create("DScrollPanel", self)

		scroller.Paint = nil
		self.Scroller = scroller

		scroller:Dock(FILL)
		scroller:SetPaintBackgroundEnabled(false)

		do --sizer
			local sizer = vgui.Create("DSizeToContents", scroller)
			self.Sizer = sizer

			scroller:AddItem(sizer)
		end

		do --hint sizer
			local sizer = vgui.Create("DSizeToContents", scroller)
			self.HintSizer = sizer

			scroller:AddItem(sizer)
		end
	end
end

function PANEL:PerformLayout(width)
	local hint_panels = self.HintPanels
	local hint_sizer = self.HintSizer
	local hint_width = math.ceil(width * 0.2)
	local margin = math.max(ScrH() / 270, 2)
	local margin_double = margin * 2
	local panels = self.Panels
	local sizer = self.Sizer

	self.Label:DockMargin(margin_double, margin, margin_double, margin)

	for index, panel in ipairs(panels) do panel:DockMargin(margin, margin_double, margin, margin_double) end

	sizer:SetWide(width - hint_width)
	sizer:SetX(hint_width)
	sizer:SizeToContents(false, true)
	hint_sizer:SetWide(hint_width)

	hint_width = hint_width - margin_double

	for index, panel in ipairs(panels) do
		local hint_panel = hint_panels[index]

		hint_panel:SetSize(hint_width, panel:GetTall())
		hint_panel:SetPos(margin, panel:GetY())
	end

	hint_sizer:SizeToContents(false, true)
end

function PANEL:SetDetails(_command_signature, command_table)
	local hint_panels = self.HintPanels
	local hint_sizer = self.HintSizer
	local panels = self.Panels
	local sizer = self.Sizer

	self.Label:SetText("#" .. PYRITION.CommandLocalizationKeys[command_table.Name])

	for index, argument_settings in ipairs(command_table.Arguments) do
		local argument_class = argument_settings.Class
		local argument_panel_class = "PyritionCommandArgument" .. argument_class

		do --right side input panel
			local panel = vgui.Create(vgui.GetControlTable(argument_panel_class) and argument_panel_class or "PyritionCommandArgumentUndefined", sizer)
			panels[index] = panel

			panel:Dock(TOP)
			panel:SetCommandArgument(argument_settings)
		end

		do --left side hint panel
			local hint_panel = vgui.Create("DLabel", hint_sizer)
			hint_panels[index] = hint_panel

			hint_panel:PyritionSetFont("PyritionDermaRegular")
			hint_panel:SetText("hint #" .. index)
			hint_panel:SetWrap(true)
		end
	end

	self:InvalidateLayout(true)
end

derma.DefineControl("PyritionCommandPaletteCardCommand", "Card used for the PyritionCommandPalette panel.", PANEL, "PyritionCommandPaletteCard")