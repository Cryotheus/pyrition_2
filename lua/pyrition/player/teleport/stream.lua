--locals
local MODEL = {}
local teleport_history = PYRITION.PlayerTeleportHistory
local teleport_history_length_bits = PYRITION.PlayerTeleportHistoryLengthBits

--stream model functions
function MODEL:Read()
	table.Empty(teleport_history)
	
	for index = 1, self:ReadUInt(teleport_history_length_bits) do
		teleport_history[index] = {
			Note = self:ReadBool() and self:ReadPlayer() or self:ReadString(),
			Position = self:ReadVector(),
			Type = self:ReadEnumeratedString("teleport_type"),
			Unix = self:ReadUInt(32),
		}
	end
end

function MODEL:Write(ply)
	local history = teleport_history[ply]
	
	self:WriteUInt(#history, teleport_history_length_bits)
	
	for index, data in ipairs(history) do
		if IsEntity(note) then
			self:WriteBool(true)
			self:WritePlayer(note)
		else
			self:WriteBool(false)
			self:WriteString(note)
		end
		
		self:WriteVector(data.Position)
		self:WriteEnumeratedString("teleport_type", data.Type)
		self:WriteUInt(data.Unix, 32)
	end
	
	self:Complete()
end

--post
PYRITION:NetStreamModelRegister("teleport", CLIENT, MODEL)