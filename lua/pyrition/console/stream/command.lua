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
			
			print("yes arg", argument_count)
			
			for index = 1, argument_count do
				local command_argument = command_arguments[index]
				local command_argument_object = command_argument_classes[command_argument.Class]
				
				print("#" .. index, command_argument, command_argument_object)
				PrintTable(istable(command_argument) and command_argument or {type(command_argument)})
				
				if command_argument_object.Read then
					local what = command_argument_object:Read(self, command_argument)
					
					print("read using obj", what)
					
					arguments[index] = what
				else
					local what = self:MaybeRead("ReadString")
					
					print("read using maybe", what)
					
					arguments[index] = what
				end
			end
			
			PrintTable(arguments)
			
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
	local valid, argument_count = PYRITION:ConsoleCommandArgumentValidate(ply, command, arguments)
	
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
	else self:WriteBool(false) end
end

--post
PYRITION:NetStreamModelRegister("command", SHARED, MODEL)