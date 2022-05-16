--locals
local duplex_set = PYRITION._DuplexSet
--local duplex_sort = PYRITION._DuplexSort
local MODEL = {}

--sync model functions
--function MODEL:FinishRead() duplex_sort(PYRITION.MapList) end

function MODEL:Initialize()
	self.Bits = PYRITION.NetEnumerationBits.map
	
	if SERVER then
		local items = table.Copy(PYRITION.MapList)
		
		self.Maximum = #items
		self.Index = 1
		self.Items = items
	else table.Empty(PYRITION.MapList) end
end

function MODEL:InitialSync(ply, emulated) return true end

function MODEL:Read()
	local bits = self.Bits
	local maps = PYRITION.MapList
	
	while net.ReadBool() do duplex_set(maps, net.ReadUInt(bits) + 1, PYRITION:NetReadEnumeratedString("map")) end
end

function MODEL:Write(ply)
	local index = self.Index
	local item = self.Items[index]
	
	net.WriteBool(true)
	net.WriteUInt(index - 1, self.Bits)
	PYRITION:NetWriteEnumeratedString("map", item, ply)
	
	if index >= self.Maximum then
		net.WriteBool(false)
		
		return true
	end
	
	self.Index = index + 1
end

--post
PYRITION:NetSyncModelRegister("map", MODEL)