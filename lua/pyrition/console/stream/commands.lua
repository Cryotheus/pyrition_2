--sync a list of commands to the client
--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses
local is_pyrition_command = PYRITION._IsPyritionCommand
local MODEL = {Priority = 60}

--local functions
local function read_command(self, parents)
	--MsgC(Color(192, 0, 255), "reading command " .. self:Distance() .. "\n")
	local name = self:ReadEnumeratedString("command")
	local required = self:ReadByte()
	
	local argument_count = self:ReadByte()
	local arguments = {Required = required}
	
	--read the list of arguments
	for index = 1, argument_count do
		local class = self:ReadEnumeratedString("command_argument")
		local command_argument = command_argument_classes[class]
		local settings = {
			Class = class,
			Optional = self:ReadBool()
		}
		
		if command_argument then
			--if we have special fields to read
			if command_argument.ReadSettings then command_argument:ReadSettings(self, settings) end
		else ErrorNoHalt("ID10T-12/C: Invalid command argument class " .. tostring(class) .. " for sync.") end
		
		arguments[index] = settings
	end
	
	table.insert(parents, name)
	PYRITION:ConsoleCommandDownload(parents, arguments)
	--MsgC(Color(0, 0, 255), "read command " .. self:Distance() .. "\n")
end

local function read_commands(self, parents)
	while self:ReadBool() do
		if self:ReadBool() then read_command(self, parents)
		else
			--MsgC(Color(0, 192, 255), "reading organizer " .. self:Distance() .. "\n")
			
			local name = self:ReadEnumeratedString("command")
			
			table.insert(parents, name)
			
			--MsgC(Color(0, 128, 255), "read organizer " .. self:Distance() .. "\n")
		end
		
		if self:ReadBool() then read_commands(self, parents) end
		
		table.remove(parents)
	end
end

local function write_command(self, _ply, parents, command)
	--MsgC(Color(192, 0, 255), "writing command " .. self:Size() .. "\n")
	local arguments = command.Arguments
	
	table.insert(parents, command.Name)
	self:WriteEnumeratedString("command", command.Name)
	self:WriteByte(arguments.Required)
	self:WriteByte(#arguments)
	
	--write the list of arguments
	for index, settings in ipairs(arguments) do
		local class = settings.Class
		local command_argument = command_argument_classes[class]
		
		self:WriteEnumeratedString("command_argument", class)
		self:WriteBool(settings.Optional)
		
		if command_argument then
			--if we have special fields to write
			if command_argument.WriteSettings then command_argument:WriteSettings(self, settings) end
		else ErrorNoHalt("ID10T-12/C: Invalid command argument class " .. tostring(class) .. " for sync.") end
	end
	--MsgC(Color(0, 0, 255), "wrote command " .. self:Size() .. "\n")
end

local function write_commands(self, ply, parents, commands)
	for index, command in pairs(commands) do
		self:WriteBool(true)
		
		local children = PYRITION:ConsoleCommandGetChildTables(command)
		
		if is_pyrition_command(command) then
			self:WriteBool(true)
			write_command(self, ply, parents, command)
		else
			--MsgC(Color(0, 192, 255), "writing organizer " .. self:Size() .. "\n")
			
			local name = command.Name
			
			self:WriteBool(false)
			self:WriteEnumeratedString("command", name)
			
			table.insert(parents, name)
			
			--MsgC(Color(0, 128, 255), "wrote organizer " .. self:Size() .. "\n")
		end
		
		if children then
			self:WriteBool(true)
			
			write_commands(self, ply, parents, children)
		else self:WriteBool(false) end
		
		table.remove(parents)
	end
	
	self:WriteBool(false)
end

--stream model functions
function MODEL:InitialSync() return true end
function MODEL:Read() read_commands(self, {}) end

function MODEL:Write(ply)
	write_commands(self, ply, {}, PYRITION:ConsoleCommandGetChildTables(PYRITION.ConsoleCommands))
	self:Complete()
end

--post
PYRITION:NetStreamModelRegister("commands", CLIENT, MODEL)