--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses
local MODEL = {Priority = 20}

--stream model functions
function MODEL:Read(ply)
	ply = ply or LocalPlayer()
	
	repeat
		local parents = {}
		
		repeat table.insert(parents, self:ReadEnumeratedString("command"))
		until self:ReadBoolNot()
		
		local command = PYRITION:ConsoleCommandGetExisting(parents)
		
		--discard if the command does not exist
		if not command then return CLIENT and ErrorNoHalt("ID10T-21: Discarding all queued commands! Invalid command read with parents '" .. table.concat(parents, ".") .. "'") end
		
		local arguments = {}
		
		if self:ReadBool() then
			local argument_count = self:ReadByte()
			local command_arguments = command.Arguments
			
			for index = 1, argument_count do
				local command_argument = command_arguments[index]
				local command_argument_object = command_argument_classes[command_argument.Class]
				
				--if we have a custom read method, use it, otherwise we default to a nullable ReadString
				if command_argument_object.Read then arguments[index] = command_argument_object:Read(self, command_argument)
				else arguments[index] = self:MaybeRead("ReadString") end
			end
			
			PYRITION:ConsoleExecute(ply, command, arguments)
		end
	until self:ReadBoolNot()
end

function MODEL:Write(_ply, command, arguments)
	if self.WroteCommand then self:WriteBool(true)
	else
		self.WroteCommand = true
		
		self:Send()
	end
	
	local command_arguments = command.Arguments
	local passed = false
	local valid, argument_count, message = PYRITION:ConsoleCommandArgumentValidate(ply, command, arguments)
	
	for index, name in ipairs(command.Parents) do
		if passed then self:WriteBool(true)
		else passed = true end
		
		self:WriteEnumeratedString("command", name)
	end
	
	self:WriteBool(false)
	
	if valid then
		self:WriteBool(true)
		self:WriteByte(math.min(argument_count, 255))
		
		for index = 1, argument_count do
			local command_argument = command_arguments[index]
			local command_argument_object = command_argument_classes[command_argument.Class]
			
			if command_argument_object.Write then command_argument_object:Write(self, command_argument, arguments[index])
			else self:MaybeWrite("WriteString", arguments[index]) end
		end
		
		return true
	else
		self:WriteBool(false)
		
		return false, argument_count, message
	end
end

--post
PYRITION:NetStreamModelRegister("command", SHARED, MODEL)