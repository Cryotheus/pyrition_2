--locals
local duplex_insert = duplex.Insert
local kick_queue --duplex of players
local kick_queue_reasons = {} --patchy table of reasons

--local functions
local function kick_think()
	for index, ply in ipairs(kick_queue) do
		ply:Kick(kick_queue_reasons[index] or "")
	end

	kick_queue = nil

	hook.Remove("Think", "PyritionPlayerKick")
	table.Empty(kick_queue_reasons)
end

--pyrition functions
function PYRITION:PlayerKick(ply, reason)
	if not kick_queue then
		kick_queue = {}

		hook.Add("Think", "PyritionPlayerKick", kick_think)
	end

	local index = duplex_insert(kick_queue, ply)

	if index then
		kick_queue_reasons[index] = reason

		return true
	end
end
