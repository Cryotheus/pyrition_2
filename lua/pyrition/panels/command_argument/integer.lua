local PANEL = {}

function PANEL:PerformLayout()

	self:SizeToChildren(false, true)
end

function PANEL:SetCommandArgument(argument_settings)
	local maximum = argument_settings.Maximum
	local minimum = argument_settings.Minimum or not argument_settings.Signed and 0

	if maximum and minimum then
		local slider = vgui.Create("PyritionLabeledSlider", self)
		self.Slider = slider

		slider:Dock(TOP)
		slider:SetRange(maximum, minimum)
	else
		do --validated text entry
			local local_player = LocalPlayer()
			local validated_entry = vgui.Create("PyritionValidatedTextEntry", self)
	
			function validated_entry:DoValidate(text) return argument_settings:Filter(local_player, text) end
	
			validated_entry:Dock(TOP)
			validated_entry:PyritionSetFont("PyritionDermaMedium")
			validated_entry:SetPlaceholderText(argument_settings.Class) --LOCALIZE: undefined argument entry
		end

		if maximum or minimum then
			local label = vgui.Create("DLabel", self)

			label:Dock(TOP)
			label:PyritionSetFont("PyritionDermaMedium")
			label:SetAutoStretchVertical(true)
			label:SetContentAlignment(4)
			label:SetWrap(true)

			--LOCALIZE: panel: PyritionCommandArgumentInteger
			if maximum then label:SetText("Up to a maximum of " .. maximum .. ".")
			elseif minimum then label:SetText("Given a minimum of " .. minimum .. ".") end
		end
	end

	self:InvalidateLayout(true)
end

derma.DefineControl("PyritionCommandArgumentInteger", "PyritionCommandArgument for the Integer command argument.", PANEL, "PyritionCommandArgument")