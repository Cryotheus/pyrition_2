--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses
local MODEL = {Priority = 60}

--local functions
local function read_command(self, parents)
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
			if command_argument.Read then command_argument:Read(self, settings) end
		else ErrorNoHalt("ID10T-12/C: Invalid command argument class " .. tostring(class) .. " for sync.") end
		
		arguments[index] = settings
	end
	
	table.insert(parents, name)
	PYRITION:ConsoleCommandDownload(parents, arguments)
end

local function read_commands(self, parents)
	while self:ReadBool() do
		--MsgC(Color(192, 0, 255), "reading command " .. self:Distance() .. "\n")
		read_command(self, parents)
		--MsgC(Color(0, 0, 255), "read command " .. self:Distance() .. "\n")
		
		if self:ReadBool() then read_commands(self, parents) end
		
		table.remove(parents)
	end
end

local function write_command(self, _ply, parents, command)
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
			if command_argument.Write then command_argument:Write(self, settings) end
		else ErrorNoHalt("ID10T-12/C: Invalid command argument class " .. tostring(class) .. " for sync.") end
	end
end

local function write_commands(self, ply, parents, commands)
	for index, command in pairs(commands) do
		self:WriteBool(true)
		
		local children = PYRITION:ConsoleCommandGetChildren(command)
		
		--MsgC(Color(192, 0, 255), "writing command " .. self:Size() .. "\n")
		write_command(self, ply, parents, command)
		--MsgC(Color(0, 0, 255), "wrote command " .. self:Size() .. "\n")
		
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
	write_commands(self, ply, {}, PYRITION:ConsoleCommandGetChildren(PYRITION.ConsoleCommands))
	self:Complete()
end

--post
PYRITION:NetStreamModelRegister("command", CLIENT, MODEL)