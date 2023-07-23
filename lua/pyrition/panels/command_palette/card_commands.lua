local PANEL = {}

function PANEL:OnRemove() PYRITION:CommandClearHaystackCache(self.CardID) end

function PANEL:OnSubmit(command_name)
	local command_haystack = PYRITION.CommandHaystack[command_name]

	if #command_haystack == 1 then
		local command_signature = command_haystack[1]
		local command_table = PYRITION.CommandRegistry[command_signature]
		
		if command_table.Arguments[1] then self:PushCard("PyritionCommandPaletteCardCommand", command_signature, command_table)
		else
			
		end
	else self:PushCard("PyritionCommandPaletteCardCommandSignatures", command_haystack) end
end

function PANEL:OnSubmitEmpty() self.CommandPalette:Remove() end

function PANEL:Search(needle)
	local finds = PYRITION:CommandFindSignatures(needle, self.CardID)
	local localization_keys = PYRITION.CommandLocalizationKeys
	local results = {}

	for index, finding in ipairs(finds) do
		local command_name = finding[1]

		table.insert(results, {
			command_name,
			PYRITION:LanguageGetPhrase(localization_keys[command_name]) or command_name
		})
	end

	return results
end

derma.DefineControl(
	"PyritionCommandPaletteCardCommands",
	"PyritionCommandPaletteCardOptions built specifically for searching commands.",
	PANEL,
	"PyritionCommandPaletteCardOptions"
)