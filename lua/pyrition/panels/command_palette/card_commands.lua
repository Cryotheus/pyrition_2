local PANEL = {}

function PANEL:Init()

end

function PANEL:OnRemove() PYRITION:CommandClearHaystackCache(self.CardID) end

function PANEL:Search(needle)
	local results = {}
	local signatures = PYRITION:CommandFindSignatures(needle, self.CardID)

	for index, signature in ipairs(signatures) do table.insert(results, {key, key}) end

	return results
end

function PANEL:Submit(choice)
	if not choice then
		choice = self.Choices[1]

		if not choice then return end
	end

end

function PANEL:OnSubmit()
	PYRITION:CommandClearHaystackCache(self.CardID)
end

derma.DefineControl(
	"PyritionCommandPaletteCardCommands",
	"PyritionCommandPaletteCardOptions built specifically for searching commands.",
	PANEL,
	"PyritionCommandPaletteCardOptions"
)