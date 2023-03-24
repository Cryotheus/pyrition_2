--table styles
--dictionary: table where all keys are strings
--duplex: table where the non-numerical parts represent the key's numerical location
--fooplex: duplex that may be missing some entry pairs entirely
--report: table where all values are true, or its sole purpose is to track presence

--please note, entries beginning with _ in the PYRITION table are local functions made global
local developer = GetConVar("developer")

local enumerations = {
	{
		Prefix = "COMMAND",

		"ERRED",
		"MISSED",
		"SUCCEEDED",
	},

	{
		DontBrand = true,
		Prefix = "IMAGE_FORMAT",

		"ABGR8888",
		"RGB888",
		"BGR888",
		"RGB565",
		"I8",
		"IA88",
		"P8",
		"A8",
		"RGB888_BLUESCREEN",
		"BGR888_BLUESCREEN",
		"ARGB8888",
		"BGRA8888",
		"DXT1",
		"DXT3",
		"DXT5",
		"BGRX8888",
		"BGR565",
		"BGRX5551",
		"BGRA4444",
		"DXT1_ONEBITALPHA",
		"BGRA5551",
		"UV88",
		"UVWQ8888",
		"RGBA16161616F",
		"RGBA16161616",
		"UVLX8888",
	},

	{
		Prefix = "WIKIFY",

		"GLOBALS",
		"CLASSES",
		"LIBRARIES",
		"HOOKS",
		"PANELS",
		"ENUMS",
		"STRUCTS",
	}
}

--false in MENU state
--was deprecated, but kept it because of stream models
SHARED = CLIENT or SERVER or false

if PYRITION then
	local removing = {}

	MsgC(color_white, "Removing functions for Pyrition's reload:")

	for key, value in pairs(PYRITION) do
		--editing the table while iterating over it... was a bad experience...
		MsgC(" " .. key)
		table.insert(removing, value)
	end

	for index, victim in ipairs(removing) do PYRITION[victim] = nil end

	MsgC("\nDone.\n")
else PYRITION = {} end

--pyrition functions
function PYRITION._drint(level, ...)
	--pr1nt with developer only
	--hide from d3bug searches
	if developer:GetInt() >= level then _G["\x70rint"](...) end
end

--post
for _, enumerations in ipairs(enumerations) do
	local prefix = enumerations.Prefix

	if enumerations.DontBrand then
		if prefix then prefix = prefix .. "_"
		else prefix = "" end
	else
		if prefix then prefix = "PYRITION_" .. prefix .. "_"
		else prefix = "PYRITION_" end
	end

	for value, name in ipairs(enumerations) do _G[prefix .. name] = value end
end