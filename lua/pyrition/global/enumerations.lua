local enumerations = {
	{
		Prefix = "COMMAND",

		"ERRED",
		"MISSED",
		"SUCCEEDED",
	},

	{
		--https://developer.valvesoftware.com/wiki/Valve_Texture_Format#VTF_enumerations
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
		--https://wiki.facepunch.com/gmod/Enums/NavDir
		Offset = -1,
		Prefix = "NAV_DIR",

		"EAST",
		"NORTH",
		"SOUTH",
		"WEST",
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
	},

	{
		--https://developer.valvesoftware.com/wiki/Valve_Texture_Format#Image_flags
		DontBrand = true,
		ExponentBase = 2,
		Prefix = "TEXTUREFLAGS",

		"POINTSAMPLE",
		"TRILINEAR",
		"CLAMPS",
		"CLAMPT",
		"ANISOTROPIC",
		"HINT_DXT5",
		"PWL_CORRECTED",
		"NORMAL",
		"NOMIP",
		"NOLOD",
		"ALL_MIPS",
		"PROCEDURAL",
		"ONEBITALPHA",
		"EIGHTBITALPHA",
		"ENVMAP",
		"RENDERTARGET",
		"DEPTHRENDERTARGET",
		"NODEBUGOVERRIDE",
		"SINGLECOPY",
		"UNUSED_00080000",
		"IMMEDIATE_CLEANUP",
		"UNUSED_00200000",
		"UNUSED_00400000",
		"NODEPTHBUFFER",
		"UNUSED_01000000",
		"CLAMPU",
		"VERTEXTEXTURE",
		"SSBUMP",
		"UNUSED_10000000",
		"BORDER",
		"UNUSED_40000000",
		"UNUSED_80000000",
	},
}

for _, enumerations in ipairs(enumerations) do
	local exponent_base = enumerations.ExponentBase
	local offset = enumerations.Offset or 0
	local prefix = enumerations.Prefix

	if enumerations.DontBrand then
		if prefix then prefix = prefix .. "_"
		else prefix = "" end
	else
		if prefix then prefix = "PYRITION_" .. prefix .. "_"
		else prefix = "PYRITION_" end
	end

	--exponential:	exponent_base ^ (index - 1) + offset
	--linear:		index + offset
	if exponent_base then for value, name in ipairs(enumerations) do _G[prefix .. name] = exponent_base ^ (value - 1) + offset end
	else for value, name in ipairs(enumerations) do _G[prefix .. name] = value + offset end end
end