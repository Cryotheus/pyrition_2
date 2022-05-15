--locals
local MODEL = {}
local teleport_history = PYRITION.PlayerTeleportHistory
local teleport_history_length_bits = PYRITION.PlayerTeleportHistoryLengthBits

--sync model functions
function MODEL:BuildWrite()
	local history = teleport_history[self.Player] or {}
	
	self.History = history
	self.Index = 1
	self.Maximum = #history
end

function MODEL:FinishRead() PYRITION:PlayerTeleportRefreshGUI() end

function MODEL:Initialize()
	self.First = true
	
	if SERVER then self:BuildWrite() end
end

function MODEL:Read()
	if self.First then
		self.First = false
		
		if net.ReadBool() then return table.Empty(teleport_history) end
	end
	
	while net.ReadBool() do
		local index = net.ReadUInt(teleport_history_length_bits) + 1
		
		if index == 1 then table.Empty(teleport_history) end
		
		teleport_history[index] = net.ReadVector()
	end
end

function MODEL:Write(ply)
	local index = self.Index
	local position = self.History[index]
	
	if position then
		if self.First then
			self.First = false
			
			net.WriteBool(false)
		end
		
		net.WriteBool(true)
		net.WriteUInt(index - 1, teleport_history_length_bits)
		net.WriteVector(position)
		
		self.Index = index + 1
		
		--more to write
		if index < self.Maximum then return end
		
		net.WriteBool(false)
	elseif self.First then net.WriteBool(true)
	else net.WriteBool(false) end
	
	--stop writing
	return true
end

--post
PYRITION:NetSyncModelRegister("teleport", MODEL)