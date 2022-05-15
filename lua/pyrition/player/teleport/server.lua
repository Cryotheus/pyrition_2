--locals
local teleport_history = PYRITION.PlayerTeleportHistory
local teleport_history_length = PYRITION.PlayerTeleportHistoryLength

--local functions
local function create_history_entry(ply, teleport_type, note)
	return {
		Note = note or "pyrition.player.teleport.note",
		Position = ply:GetPos(),
		Type = teleport_type,
		Unix = os.time(),
	}
end

--pyrition functions
function PYRITION:PlayerTeleport(ply, destination, teleport_type, note)
	local history = teleport_history[ply]
	
	print("perform teleport", ply, destination, teleport_type, note)
	
	if history then if table.insert(history, create_history_entry(ply, teleport_type, note)) > teleport_history_length then table.remove(history, 1) end
	else teleport_history[ply] = {create_history_entry(ply, teleport_type, note)} end
	
	ply:SetPos(destination)
	self:NetSyncAdd("teleport", ply)
end

function PYRITION:PlayerTeleportReturn(ply, entry)
	local history = teleport_history[ply]
	
	if history and next(history) then
		local count = #history
		local entry = entry or count
		local poll = history[entry]
		
		if poll then
			for index = count, entry, -1 do table.remove(history, index) end
			
			ply:SetPos(poll.Position)
			self:NetSyncAdd("teleport", ply)
			
			return true
		end
		
		return false, "pyrition.player.teleport.no_entry"
	end
	
	return false, "pyrition.player.teleport.no_history"
end

--hooks
hook.Add("PlayerDisconnected", "PyritionPlayerTeleport", function(ply) teleport_history[ply] = nil end)

--[[

[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
   2. dlib_has_nothing_to_do_with_this_traceback - [C]:-1
    3. CallStatic - lua/dlib/modules/hook.lua:1106
     4. unknown - lua/dlib/modules/hook.lua:1189


[ERROR] addons/pyrition/lua/pyrition/net/server.lua:100: ID10T-3.1: Attempt to write enumerated string using non-existant enumeration ""
  1. assert - [C]:-1
   2. NetWriteEnumeratedString - addons/pyrition/lua/pyrition/net/server.lua:100
    3. model - addons/pyrition/lua/pyrition/player/teleport/sync.lua:59
     4. __event - addons/pyrition/lua/pyrition/net/sync/server.lua:110

[pyrition] Warning! A net message (pyrition_sync) is already started! Discarding in favor of the new message! (pyrition_sync)
  1. unknown - addons/pyrition/lua/pyrition/net/sync/server.lua:84
]]