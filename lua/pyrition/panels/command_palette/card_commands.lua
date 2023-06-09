local PANEL = {}

function PANEL:Init()

end

function PANEL:OnRemove() PYRITION:CommandClearHaystackCache(self.CardID) end

function PANEL:OnSubmit(value)
	local command_name = value[1]
	local command_haystack = PYRITION.CommandHaystack[command_name]

	PYRITION:CommandClearHaystackCache(self.CardID)

	if #command_haystack == 1 then

	else
		self:PushCard("PyritionCommandPaletteCardSimpleOptions", value[1], value[3])
	end
end

function PANEL:Search(needle)
	local finds = PYRITION:CommandFindSignatures(needle, self.CardID)
	local localization_keys = PYRITION.CommandLocalizationKeys
	local results = {}

	for index, finding in ipairs(finds) do
		local command_name = finding[1]

		table.insert(results, {
			command_name,
			PYRITION:LanguageGetPhrase(localization_keys[command_name]) or command_name,
			finding[2]
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