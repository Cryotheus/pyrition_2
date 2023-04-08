util.AddNetworkString("pyrition_stream")

--locals
local active_streams = PYRITION.NetStreamsActive
local stream_send_queue = PYRITION.NetStreamQueue
local table_insert = table.insert

--pyrition functions
function PYRITION:NetStreamModelAdd(class, target)
	if target and not IsEntity(target) then
		local targets = recipient_iterable(target)

		if targets then
			for index, target in ipairs(targets) do self:NetStreamModelAdd(target) end

			return
		end
	end

	self:NetStreamModelCreate(class, target)
end

function PYRITION:NetStreamThink()
	local completed_players = {}

	for ply, stream_queue in pairs(stream_send_queue) do
		if IsEntity(ply) then
			net.Start("pyrition_stream")
			self:NetStreamWrite(stream_queue)
			net.Send(ply)

			if table.IsEmpty(stream_queue) then table_insert(completed_players, ply) end
		else
			ErrorNoHalt("Illegal stream send queue key of type '" .. type(ply) .. "'\nStream will be dropped.\nMake sure you're not mixing the client and server realms.")
			table_insert(completed_players, ply)
		end
	end

	for index, ply in ipairs(completed_players) do stream_send_queue[ply] = nil end
end

--hooks
hook.Add("PlayerDisconnected", "PyritionNetStream", function(ply)
	active_streams[ply] = nil
	stream_send_queue[ply] = nil
end)

hook.Add("PyritionNetStreamRegisterClass", "PyritionNetStream", function(class, _realm, enumerated) if enumerated then PYRITION:NetAddEnumeratedString("Stream", class) end end)

--post
PYRITION:NetAddEnumeratedString("Stream")