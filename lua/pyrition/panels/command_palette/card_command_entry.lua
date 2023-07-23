local PANEL = {}

function PANEL:Init()
	local parent = self

	do --top label
		local label = vgui.Create("DLabel", self)

		label:Dock(TOP)
		label:PyritionSetFont("PyritionDermaMedium")
		label:SetAutoStretchVertical(true)
		label:SetContentAlignment(4)

		function label:Paint()
			self:SetTextColor(parent:GetTextStyleColor())
		end

		self.TopLabel = label
	end

	do --top label
		local label = vgui.Create("DLabel", self)

		label:Dock(TOP)
		label:PyritionSetFont("PyritionDermaMedium")
		label:SetAutoStretchVertical(true)
		label:SetContentAlignment(4)

		function label:Paint()
			self:SetTextColor(parent:GetTextStyleColor())
		end

		self.BottomLabel = label
	end

	do --spacer
		local spacer = vgui.Create("Panel", self)
		self.SpacerPanel = spacer

		spacer:Dock(TOP)
	end

	self:SetText("")
end

function PANEL:PerformLayout()
	local margin = math.max(ScrH() / 270, 2)

	self.BottomLabel:DockMargin(margin, margin, 0, 0)
	self.TopLabel:DockMargin(margin, margin, 0, 0)
	self.SpacerPanel:SetHeight(margin)
	self:SizeToChildren(false, true)
end

function PANEL:SetValue(command_signature)
	local command_table = PYRITION.CommandRegistry[command_signature]

	if command_table.Arguments[1] then
		self.NoCommandArguments = false

		self.BottomLabel:SetText(table.concat(select(2, PYRITION:CommandSplitSignature(command_signature)), ", "))
		self.BottomLabel:SetVisible(true)
		self.TopLabel:SetText("the hints for the aruments or something")
	else
		self.NoCommandArguments = true

		self.BottomLabel:SetVisible(false)
		self.TopLabel:SetText("No arguments, selecting will immediately execute.")
	end
end

derma.DefineControl("PyritionCommandPaletteCardCommandEntry", "An entry in the PyritionCommandPaletteCardCommand panel.", PANEL, "DButton")