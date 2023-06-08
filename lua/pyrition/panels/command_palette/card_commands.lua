local PANEL = {}

function PANEL:Init()

end

function PANEL:OnRemove() PYRITION:CommandClearHaystackCache(self.CardID) end
function PANEL:OnSubmit() PYRITION:CommandClearHaystackCache(self.CardID) end

function PANEL:Search(needle)
	local finds = PYRITION:CommandFindSignatures(needle, self.CardID)
	local results = {}

	for index, finding in ipairs(finds) do table.insert(results, {finding[1], finding[1]}) end

	return results
end

function PANEL:Submit(choice)
	if not choice then
		choice = self.Choices[1]

		if not choice then return end
	end
end

derma.DefineControl(
	"PyritionCommandPaletteCardCommands",
	"PyritionCommandPaletteCardOptions built specifically for searching commands.",
	PANEL,
	"PyritionCommandPaletteCardOptions"
)