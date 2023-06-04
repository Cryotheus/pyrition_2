--table styles
--dictionary: table where all keys are strings
--duplex: table where the non-numerical parts represent the key's numerical location
--fooplex: duplex that may be missing some entry pairs entirely
--report: table where all values are true, or its sole purpose is to track presence

--please note, functions beginning with _ in the PYRITION method table should not be called as a method
--this is typically because the function is built for caching as an upvalue
local developer = GetConVar("developer")

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