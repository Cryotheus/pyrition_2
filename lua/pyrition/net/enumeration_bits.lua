--locals
local MODEL = {
	EnumerateClass = false,
	Priority = 65535
}

--stream model functions
function MODEL:Initialize() self:Send() end
function MODEL:InitialSync() return true end

function MODEL:Read()
	local enumeration_bits = PYRITION.NetEnumerationBits
	local net_enumerations = PYRITION.NetEnumeratedStrings
	
	while self:ReadBool() do
		local namespace = self:ReadString()
		enumeration_bits[namespace] = self:ReadUInt(5) + 1
		
		if not net_enumerations[namespace] then net_enumerations[namespace] = {} end
	end
	
	--[[]
	repeat
		local namespace = self:ReadString()
		enumeration_bits[namespace] = self:ReadUInt(5) + 1
		
		if not net_enumerations[namespace] then net_enumerations[namespace] = {} end
	until self:ReadBoolNot()]]
end

function MODEL:Write()
	for namespace, bits in pairs(self.Bits or PYRITION.NetEnumerationBits) do
		self:WriteBool(true)
		self:WriteString(namespace)
		self:WriteUInt(bits - 1, 5)
	end
	
	--[[]
	local passed = false
	
	for namespace, bits in pairs(self.Bits or PYRITION.NetEnumerationBits) do
		if passed then self:WriteBool(true)
		else passed = true end
		
		self:WriteString(namespace)
		self:WriteUInt(bits - 1, 5)
	end
	
	self:WriteBool(false)
	self:Complete()]]
end

--post
PYRITION:NetStreamModelRegister("enumeration_bits", CLIENT, MODEL)