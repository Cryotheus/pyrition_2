--locals
local command_argument_classes = PYRITION.ConsoleCommandArgumentClasses
local MODEL = {}

--sync model functions
function MODEL:Initialize()
	self.CommandParents = {}
	
	if SERVER then
		self.CommandTree = PYRITION:ConsoleCommandGetTree()
		self.KeyStack = {}
	end
end

function MODEL:InitialSync(ply, emulated)
	--return true if you want to make a sync when the client loads in
	--this is called on the model's table, not on a model with metamethods!
	return true
end

function MODEL:Read()
	local parents = self.CommandParents
	
	if net.ReadBool() then --we are reading a command
		local index = 0
		local name = PYRITION:NetReadEnumeratedString("command")
		local required = net.ReadUInt(8)
		
		local arguments = {Required = required}
		
		while net.ReadBool() do
			index = index + 1
			local settings = {}
			
			if index <= required then settings.Optional = net.ReadBool() end
			
			local class = PYRITION:NetReadEnumeratedString("command_argument")
			local functions = command_argument_classes[class]
			
			settings.Class = class
			
			if functions then
				local read_function = functions[4]
				
				if read_function then read_function(settings) end
			else error('ID10T-12/C: Invalid command argument class ' .. tostring(class) .. ' for sync.') end
			
			arguments[index] = settings
		end
		
		table.insert(parents, name)
		
		PYRITION:ConsoleCommandDownload(parents, arguments)
		
		--bool = child commands follow
		if not net.ReadBool() then table.remove(parents) end
	else --we are reading popping instructions
		--bool = do we have more to read?
		if net.ReadBool() then table.remove(parents)
		else return true end
	end
	
	--this tells the client to re-run the Read method
	self.Retry = true
end

function MODEL:Write(ply)
	local branch = self.CommandTree
	local key_stack = self.KeyStack
	local key_index = math.max(#key_stack, 1)
	local parents = self.CommandParents
	
	--move down into the table containing our sibling commands
	for index, parent in ipairs(parents) do branch = branch[parent] end
	
	--key_stack[key_index] is false if we are on the first key, thus the usage of "or nil"
	local next_key, next_value = next(branch, key_stack[key_index] or nil)
	
	if next_value then --if there is stuff remaining in this table, write it!
		key_stack[key_index] = next_key
		
		net.WriteBool(true)
		
		--writes a string with compression
		local command = PYRITION:ConsoleCommandGetExisting(parents)[next_key]
		local command_arguments = command.Arguments
		local required = command_arguments.Required
		
		PYRITION:NetWriteEnumeratedString("command", next_key, ply)
		net.WriteUInt(required, 8)
		
		for index, argument_data in ipairs(command_arguments) do
			net.WriteBool(true)
			
			if index <= required then net.WriteBool(argument_data.Optional or false) end
			
			local class = argument_data.Class
			local functions = command_argument_classes[class]
			
			if functions then
				local write_function = functions[3]
				
				PYRITION:NetWriteEnumeratedString("command_argument", class, ply)
				
				if write_function then write_function(argument_data) end
			else
				ErrorNoHalt('ID10T-12/S: Invalid command argument class ' .. tostring(class) .. ' for sync.')
				
				break
			end
		end
		
		net.WriteBool(false)
		
		--next_value contains the children commands' names of next_key
		if table.IsEmpty(next_value) then net.WriteBool(false)
		else
			net.WriteBool(true)
			table.insert(key_stack, false)
			table.insert(parents, next_key)
		end
	else --otherwise send instructions to pop the parent or quit the sync
		net.WriteBool(false)
		
		if key_index == 1 then --quit sync
			net.WriteBool(false)
			
			return true
		else --instruct we have more to send, so pop and continue the sync
			net.WriteBool(true)
			table.remove(key_stack)
			table.remove(parents)
		end
	end
end

--post
PYRITION:NetSyncModelRegister("command", MODEL)