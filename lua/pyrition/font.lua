local panel_meta = FindMetaTable("Panel")
local screen_height = ScrH()

PYRITION.FontLookup = PYRITION.FontLookup or {} --table[name] = actual font name
PYRITION.FontPanels = PYRITION.FontPanels or {} --duplex = Panel
PYRITION.FontRegistry = PYRITION.FontRegistry or {} --table[name] = FontData
PYRITION.Fonts = PYRITION.Fonts or {} --table[name] = table[size] = true

function panel_meta:PyritionSetFont(name)
	---ARGUMENTS: string/nil
	---SEE: PYRITION:FontRegister
	---Sets the panel's font to a scaling font registered with $$PYRITION:FontRegister.
	---When the user's screen resolution (height) changes, $&Panel:SetFont will also be called.
	local panels = PYRITION.FontPanels

	if name then
		self.PyritionFont = name

		duplex.Insert(panels, self)

		if self.SetFont then return self:SetFont(PYRITION:FontGet(name)) end
	else
		self.PyritionFont = nil

		if panels[self] then duplex.Remove(panels, self) end
	end
end

function PYRITION:FontGet(name) return self.FontLookup[name] end

function PYRITION:FontRegister(name, font_data)
	self.FontRegistry[name] = font_data
	self.Fonts[name] = {}

	font_data.size = font_data.size or 13
	font_data.weight = font_data.weight or 500

	local size = self:FontScale(font_data.size)
	local font_name = "Pyrition_" .. size .. "_" .. name

	font_data = table.Copy(font_data)
	font_data.size = size
	font_data.weight = PYRITION:FontScale(font_data.weight)
	font_lookup[name] = font_name
	fonts[size] = true

	surface.CreateFont(font_name, font_data)
end

function PYRITION:FontScale(value) return math.max(math.Round(value * screen_height / 1440), 0) end
function PYRITION:FontScaleSize(size) return math.Clamp(math.Round(size * screen_height / 1440), 4, 255) end

hook.Add("OnScreenSizeChanged", "PyritionFont", function(_old_screen_width, old_screen_height)
	screen_height = ScrH()

	if old_screen_height == screen_height then return end

	local font_lookup = PYRITION.FontLookup
	local fonts = PYRITION.Fonts
	local panels = PYRITION.FontPanels

	--update fonts
	for name, font_data in pairs(PYRITION.FontRegistry) do
		local size = PYRITION:FontScaleSize(font_data.size)

		local font_name = "Pyrition_" .. size .. "_" .. name
		local fonts = fonts[name]

		if fonts[size] then font_lookup[name] = font_name
		else
			font_data = table.Copy(font_data)
			font_data.size = size
			font_data.weight = PYRITION:FontScale(font_data.weight)
			font_lookup[name] = font_name
			fonts[size] = true

			surface.CreateFont(font_name, font_data)
		end
	end

	--set panels' fonts to the new font
	for index, panel in ipairs(panels) do
		if panel:IsValid() then
			if panel.SetFont then panel:SetFont(PYRITION:FontGet(panel.PyritionFont)) end
		else duplex.Unset(panels, index) end
	end

	duplex.Collapse(panels)
end)