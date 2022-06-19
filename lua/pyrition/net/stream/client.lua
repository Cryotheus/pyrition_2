--pyrition functions
function PYRITION:NetStreamModelAdd(class) self:NetStreamModelCreate(class) end

function PYRITION:NetStreamThink()
	net.Start("pyrition_stream")
	self:NetStreamWrite(self.NetStreamQueue)
	net.SendToServer()
end