--locals
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
		local name = PYRITION:NetReadEnumeratedString("command")
		
		table.insert(parents, name)
		
		PYRITION:ConsoleCommandRegister(parents, {Downloaded = true})
		
		--bool = child commands follow
		if not net.ReadBool() then table.remove(parents) end
	else --we are reading popping instructions
		--bool = do we have more to read?
		if net.ReadBool() then table.remove(parents)
		else return true end
	end
	
	--don't worry about a stack overflow, we can't send more than 64KB in one message anyways
	self:Read()
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
		PYRITION:NetWriteEnumeratedString("command", next_key, ply)
		
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