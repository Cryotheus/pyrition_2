--locals
local MODEL = {
	EnumerateClass = false,
	Priority = 65535
}

--stream model functions
function MODEL:InitialSync(ply, emulated) return true end

function MODEL:Read(ply)
	local enumeration_bits = PYRITION.NetEnumerationBits
	local net_enumerations = PYRITION.NetEnumeratedStrings
	
	repeat
		local namespace = self:ReadString()
		enumeration_bits[namespace] = self:ReadUInt(5) + 1
		
		if not net_enumerations[namespace] then net_enumerations[namespace] = {} end
	until not self:ReadBool()
end

function MODEL:Write(ply)
	local passed = false
	
	for namespace, bits in pairs(self.Bits or PYRITION.NetEnumerationBits) do
		if passed then self:WriteBool(true)
		else passed = true end
		
		self:WriteString(namespace)
		self:WriteUInt(bits - 1, 5)
	end
	
	self:WriteBool(false)
	self:Complete()
end

--post
PYRITION:NetStreamModelRegister("enumeration_bits", CLIENT, MODEL)