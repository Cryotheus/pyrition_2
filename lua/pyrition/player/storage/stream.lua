--locals
local MODEL = {CopyOptimization = true}

--stream model functions
function MODEL:InitialSync() return true end

function MODEL:Read()
	print(self, "rec!")
	
	while self:ReadBool() do
		local ply = self:ReadClient()
		
		print(self, "read", ply)
		
		if self:ReadBool() then --false if we are deleting the player's storage
			local player_storage = PYRITION.PlayerStoragePlayers[ply]
			
			if not player_storage then
				player_storage = {}
				PYRITION.PlayerStoragePlayers[ply] = player_storage
			end
			
			while self:ReadBool() do PYRITION:PlayerStorageRead(self, ply, self:ReadEnumeratedString("storage")) end
		else PYRITION.PlayerStoragePlayers[ply] = nil end
	end
end

function MODEL:Write(_ply, data)
	--[[
	if not data then
		print(self, "no data table")
		debug.Trace()
		
		return
	end --]]
	
	for ply, player_storages in pairs(data) do
		self:WriteBool(true)
		self:WriteClient(ply)
		
		--print(self, "wrote", ply)
		
		if player_storages then
			self:WriteBool(true)
			
			for key, fields in pairs(player_storages) do
				if next(fields) then
					self:WriteBool(true)
					self:WriteEnumeratedString("storage", key)
					PYRITION:PlayerStorageWrite(self, ply, key, fields)
				end
			end
			
			self:WriteBool(false)
		else self:WriteBool(false) end --tell the client to delete the storage
	end
end

function MODEL:WriteInitialSync()
	for ply, player_storages in pairs(PYRITION.PlayerStoragePlayers) do
		self:WriteBool(true)
		self:WriteClient(ply)
		self:WriteBool(true)
		
		for key, stream_method in pairs(PYRITION.PlayerStorageStreamMethods) do
			self:WriteBool(true)
			self:WriteEnumeratedString("storage", key)
			PYRITION:PlayerStorageWrite(self, ply, key, true)
		end
		
		self:WriteBool(false)
	end
end

--post
PYRITION:NetStreamModelRegister("storage", CLIENT, MODEL)