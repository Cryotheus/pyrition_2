local duplex_set = duplex.Set
local map_status = PYRITION.MapStatus
local map_votes = PYRITION.MapVotes
local max_players_bits = PYRITION.NetMaxPlayerBits
local MODEL = {Priority = 20}

local function read_map(self, index)
	local map = self:ReadEnumeratedString("PyritionMap")
	map_status[index] = self:ReadBool()

	local votes = self:ReadUInt(max_players_bits)
	map_votes[map] = votes ~= 0 and votes or nil

	duplex_set(PYRITION.MapList, index, map)
end

local function write_map(self, _update_maps, map)
	self:WriteEnumeratedString("PyritionMap", map)
	self:WriteBool(map_status[map])
	self:WriteUInt(map_votes[map] or 0, max_players_bits)
end

function MODEL:InitialSync() return next(PYRITION.MapList) and true or false end

function MODEL:Read()
	local bits = PYRITION.NetEnumerationBits.PyritionMap

	--true if this is the complete list and in order
	if self:ReadBool() then for index = 1, self:ReadUInt(bits) + 1 do read_map(self, index) end
	else for _ = 0, self:ReadUInt(bits) do read_map(self, self:ReadUInt(bits) + 1) end end
end

function MODEL:Write(_ply, update_maps)
	local bits = PYRITION.NetEnumerationBits.PyritionMap

	if update_maps == PYRITION.MapList then --reference check because I'm worried about the order
		self:WriteBool(true) --true because the maps being written are in order
		self:WriteUInt(#update_maps - 1, bits)

		for index, map in ipairs(update_maps) do write_map(self, update_maps, map) end
	else
		self:WriteBool(false) --false because the maps being written may not be in order
		self:WriteUInt(#update_maps - 1, bits)

		for index, map in ipairs(update_maps) do
			self:WriteUInt(index - 1, bits)
			write_map(self, update_maps, map)
		end
	end

	if not self.Sending then self:Send() end
end

function MODEL:WriteInitialSync()
	self:WriteBool(true) --true because the maps being written are in order
	self:WriteUInt(#PYRITION.MapList - 1, PYRITION.NetEnumerationBits.PyritionMap)

	for index, map in ipairs(PYRITION.MapList) do write_map(self, update_maps, map) end
end

PYRITION:NetStreamModelRegister("PyritionMap", CLIENT, MODEL)