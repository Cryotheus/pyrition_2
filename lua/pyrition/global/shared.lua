--table styles
--dictionary: table where all keys are strings
--duplex: table where the non-numerical parts represent the key's numerical location
--fooplex: duplex that may be missing some entry pairs entirely
--report: table where all values are true, or its sole purpose is to track presence

--please note, entries beginning with _ in the PYRITION table are local functions made global
local developer = GetConVar("developer")

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

function PYRITION._drint(level, ...)
	--p rint with developer only
	if developer:GetInt() >= level then print(...) end
end