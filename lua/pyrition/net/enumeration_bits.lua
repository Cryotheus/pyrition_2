--locals
local MODEL = {
	EnumerateClass = false,
	Priority = 65535
}

--sync model functions
function MODEL:BuildWriteList(bits)
	local items = {}
	
	for key, value in pairs(bits or PYRITION.NetEnumerationBits) do table.insert(items, key) end
	
	self.Items = items
	self.Maximum = #items
	
	return items
end

function MODEL:FinishWrite() self.Tree = nil end

function MODEL:Initialize()
	if SERVER then
		self:BuildWriteList()
		
		self.Index = 1
	end
end

function MODEL:InitialSync(ply, emulated)
	--elevated priority for initial enum syncs
	self.Priority = self.Priority + 1
	
	return true
end

function MODEL:Read()
	local net_bits = PYRITION.NetEnumerationBits
	local net_enumerations = PYRITION.NetEnumeratedStrings
	
	repeat
		local namespace = net.ReadString()
		
		net_bits[namespace] = net.ReadUInt(5) + 1
		
		if not net_enumerations[namespace] then net_enumerations[namespace] = {} end
	until not net.ReadBool()
end

function MODEL:Write(ply)
	local index = self.Index
	local namespace = self.Items[index]
	
	net.WriteString(namespace)
	net.WriteUInt(PYRITION.NetEnumerationBits[namespace] - 1, 5)
	
	if index >= self.Maximum then
		net.WriteBool(false)
		
		return true
	end
	
	net.WriteBool(true)
	
	self.Index = index + 1
end

--post
PYRITION:NetSyncModelRegister("enumeration_bits", MODEL)