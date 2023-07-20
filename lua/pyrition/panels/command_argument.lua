local PANEL = {}

function PANEL:PerformLayout() self:SizeToChildren(false, true) end
function PANEL:SetCommandArgument(_argument_settings, _hint) end

derma.DefineControl("PyritionCommandArgument", "Base panel for setting a command argument.", PANEL, "DSizeToContents")