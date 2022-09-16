--locals
local bits = PYRITION._Bits

--pyrition functions
function PYRITION:PlayerStorageRead(stream, ply, key)
	local stream_methods = self.PlayerStorageStreamMethods[key]
	
	assert(stream_methods, "ID10T-23/C: Missing stream methods for syncing storage " .. tostring(key))
	
	local player_storage = self.PlayerStoragePlayers[ply][key]
	
	if not player_storage then
		player_storage = {}
		self.PlayerStoragePlayers[ply][key] = player_storage
	end
	
	--read the value of each field now
	--starting from zero instead of one so we run the missing +1 iteration
	for index = 0, stream:ReadUInt(stream_methods._CountBits) do
		local field = stream:ReadEnumeratedString("storage_field")
		player_storage[field] = stream[stream_methods[field]](stream)
	end
end

--pyrition hooks
function PYRITION:PyritionPlayerStorageRegisterSyncs(key, stream_methods)
	local count = 0
	local fields = {}
	
	--prefix the methods with write
	for field, method in pairs(stream_methods) do
		count = count + 1
		
		table.insert(fields, field)
		
		if isstring(method) then stream_methods[field] = "Read" .. method end
	end
	
	self.PlayerStorageStreamMethods[key] = stream_methods
	stream_methods._Count = count
	stream_methods._CountBits = bits(count)
	stream_methods._Fields = fields
end

--post
PYRITION:GlobalHookCreate("PlayerStorageRegisterSyncs")