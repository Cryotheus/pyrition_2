--local functions
local function insert_if_matching(completions, argument, insertion, position)
	if string.StartWith(insertion, argument) then
		if position then return table.insert(completions, position, insertion) end

		return table.insert(completions, insertion)
	end
end

--globals
PYRITION._InsertIfMatching = insert_if_matching
PYRITION.ConsoleCommandRegistry = PYRITION.ConsoleCommandRegistry or {}
PYRITION.ConsoleCommandSignedRegistry = PYRITION.ConsoleCommandSignedRegistry or {}
PYRITION.ConsoleCommandSignatureTree = PYRITION.ConsoleCommandSignatureTree or {}

--pyrition functions
function PYRITION:PyritionConsoleComplete(_executor, _command, _arguments)

end

function PYRITION:ConsoleCommandGet(command_signature) --returns command_table, signature_index
	local command_table = self.ConsoleCommandSignedRegistry[command_signature]

	return command_table, command_table.Signatures[string.sub(command_signature, command_table.SignatureStart)]
end

function PYRITION:ConsoleCommandGetSignatures(command_path)
	return self.ConsoleCommandRegistry[command_path].Signatures
end

function PYRITION:ConsoleCommandSignatureTreeSet(command_table)
	local tree = self.ConsoleCommandSignatureTree

	for index, word in ipairs(command_table.PathWords) do
		local branch = tree[word]

		if not branch then 
			branch = {}
			tree[word] = branch
		end

		tree = branch
	end

	for index, signature in ipairs(command.Signatures) do tree[index] = signature end
end

--pyrition hooks
function PYRITION:PyritionConsoleCommandExecute(executor, command, signature_index, arguments)
	local _valid_arguments, _validation_message, _validation_phrases = self:ConsoleCommandArgumentsValidate(executor, command, signature_index, arguments)

	--TODO: this
end

function PYRITION:PyritionConsoleCommandRegister(command_path, command_table)
	assert(not string.find(command_path, "[`~%?]"), "Command path cannot contain a the following characters: ` ~ ?") --TODO: make an ID10T error message
	assert(not string.find(command_path, "  +"), "Command path words should only be spaced apart by one space.")

	local path_length = #command_path

	assert(select(2, string.find(text, "[%S ]+")) == path_length, "Command path words should only be spaced apart by one space.")
	assert(utf8.len(command_path) == path_length, "Command path cannot contain any unicode characters including invalid ones.")

	local arguments = command_table.Arguments
	local existing_command = self.ConsoleCommandRegistry[command_path]
	local registry = self.ConsoleCommandRegistry
	local signatures = {}
	local signed_registry = self.ConsoleCommandSignedRegistry

	if existing_command then
		--clear the old signatures
		for index, signatures in ipairs(existing_command.Signatures) do signed_registry[command_path .. "~" .. signatures] = nil end
	end

	command_table.Path = command_path
	command_table.PathLength = path_length
	command_table.PathWords = string.Split(command_path, " ")
	command_table.SignatureStart = path_length + 2
	command_table.Signatures = signatures

	if not istable(arguments[1]) then arguments = {arguments} end

	for list_index, argument_list in ipairs(arguments) do
		local signature_builder = ""

		for text_index, argument_text in ipairs(argument_list) do
			local argument_object = self:ConsoleCommandArgumentParse(argument_text)

			arguments[text_index] = argument_object
			signature_builder = signature_builder .. argument_object.Class .. " "
		end

		signature_builder = string.sub(signature_builder, 1, -2)
		signatures[list_index] = signature_builder
		signatures[signature_builder] = list_index
		signed_registry[command_path .. "~" .. signature_builder] = command_table
	end

	registry[command_path] = command_table

	self:ConsoleCommandSignatureTreeSet(command_table)
end

--post
PYRITION:GlobalHookCreate("ConsoleCommandRegister")