local MODEL = {CopyOptimization = true, Priority = 60}

function MODEL:InitialSync() return true end

function MODEL:Read()
	local bits = PYRITION.NetEnumerationBits.Command


end

function MODEL:Write(_ply)
	local bits = PYRITION.NetEnumerationBits.Command

	

	if not self.Sending then self:Send() end
end

PYRITION:NetStreamModelRegister("Map", CLIENT, MODEL)
