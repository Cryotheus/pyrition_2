--table styles
--dictionary: table where all keys are strings
--duplex: table where the non-numerical parts represent the key's numerical location
--fooplex: duplex that may be missing some entry pairs entirely
--report: table where all values are true, or its sole purpose is to track presence

--please note, entries beginning with _ in the PYRITION table are local functions made global
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

function PYRITION._drint(level, ...)
	--print with developer only
	if developer:GetInt() >= level then print(...) end
end

--TODO: commands
--bring
--cleanup
--freeze
--god
--goto
--jail
--map
--message
--noclip
--respawn
--return
--send
--slap
--strip
--who