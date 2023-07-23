local PANEL = {}

function PANEL:PerformLayout() self:SizeToChildren(false, true) end

function PANEL:SetCommandArgument(argument_settings)
	local local_player = LocalPlayer()
	local validated_entry = vgui.Create("PyritionValidatedTextEntry", self)

	function validated_entry:DoValidate(text) return argument_settings:Filter(local_player, text) end

	validated_entry:Dock(TOP)
	validated_entry:PyritionSetFont("PyritionDermaMedium")
	validated_entry:SetPlaceholderText(argument_settings.Class) --LOCALIZE: undefined argument entry
	self:InvalidateLayout(true)
end

derma.DefineControl("PyritionCommandArgumentUndefined", "PyritionCommandArgument for command arguments whithout a panel.", PANEL, "PyritionCommandArgument")