local rebuild_camel_case = PYRITION._RebuildCamelCase

function finds_sorter(alpha, bravo)
	local alpha_score, bravo_score = alpha[3], bravo[3]

	--same score? alphabetically sort string
	if alpha_score == bravo_score then return alpha[1] < bravo[1] end

	return alpha_score > bravo_score
end

PYRITION.CommandHaystack = PYRITION.CommandHaystack or {}
PYRITION.CommandHaystackCache = PYRITION.CommandHaystackCache or {}
PYRITION.CommandLastHaystackNeedle = PYRITION.CommandLastHaystackNeedle or {}
PYRITION.CommandRegistry = PYRITION.CommandRegistry or {}

function PYRITION:Command(command_signature, arguments)

end

function PYRITION:CommandClearHaystackCache(namespace)
	self.CommandHaystackCache[namespace] = nil
	self.CommandLastHaystackNeedle[namespace] = nil
end

function PYRITION:CommandFindSignatures(needle, namespace)
	local finds = {}
	local upper_needle = string.upper(needle)

	if namespace then --progressively optimizing search
		local haystack
		local last_needle = self.CommandLastHaystackNeedle[namespace]
		local removals = {}
		self.CommandLastHaystackNeedle[namespace] = needle

		if last_needle and string.StartsWith(needle, last_needle) then
			haystack = self.CommandHaystackCache[namespace] or table.Copy(self.CommandHaystack)
		else
			haystack = table.Copy(self.CommandHaystack)
			self.CommandHaystackCache[namespace] = nil
		end

		if reset_namespace then
			haystack = table.Copy(self.CommandHaystack)
			self.CommandHaystackCache[namespace] = nil
		else haystack = self.CommandHaystackCache[namespace] or table.Copy(self.CommandHaystack) end

		for key, signatures in pairs(haystack) do
			local upper_key = string.upper(key)

			if upper_key == upper_needle then table.insert(finds, {key, signatures, 100})
			elseif string.StartsWith(upper_key, upper_needle) then table.insert(finds, {key, signatures, 50})
			else table.insert(removals, key) end
		end

		for index, key in ipairs(removals) do haystack[key] = nil end
	else --simple search
		for key, signatures in pairs(self.CommandHaystack) do
			local upper_key = string.upper(key)

			if upper_key == upper_needle then table.insert(finds, {key, signatures, 100})
			elseif string.StartsWith(upper_key, upper_needle) then table.insert(finds, {key, signatures, 50})  end
		end
	end

	table.sort(finds, finds_sorter)

	return finds
end

function PYRITION:CommandSplitSignature(command_signature)
	local tilde = string.find(command_signature, "~", 1, true)

	if tilde then
		local argument_signature = string.sub(command_signature, tilde + 1, -1)
		local command_name = string.sub(command_signature, 1, tilde - 1)

		return command_name, string.Explode("_", argument_signature), argument_signature
	end

	return nil, string.Explode("_", command_signature), command_signature
end

function PYRITION:HOOK_CommandRegister(name, command_table)
	assert(not string.find(name, "%s"), "CommandRegister cannot accept a name with whitespace.")
	assert(string.find(name, "%u") and not string.find(name, "[^%a%d]"), "CommandRegister cannot accept a name that is not CamelCase (digits allowed).")
	assert(command_table.Execute, "CommandRegister was given a command table without an Execute method.")

	local argument_signature

	if command_table.Arguments then
		local argument_settings = command_table.Arguments
		local argument_signatures = {}

		for index, settings in ipairs(argument_settings) do
			local new_settings = self:CommandArgumentParseSettings(settings)
			argument_settings[index] = new_settings
			argument_signatures[index] = new_settings.Class
		end

		argument_signature = table.concat(argument_signatures, "_")
	else
		argument_signature = ""
		command_table.Arguments = {}
	end

	local command_signature = name .. "~" .. argument_signature
	command_table.ArgumentSignature = argument_signature
	command_table.Name = name
	command_table.Signature = command_signature

	return self:CommandRegisterFinalization(name, command_signature, command_table)
end

function PYRITION:CommandRegisterFinalization(name, command_signature, command_table)
	--"soft" update for the command palette's cache
	if next(self.CommandHaystackCache) then table.Empty(self.CommandHaystackCache) end

	local command_haystack = self.CommandHaystack[name]
	command_table.LocalizationKey = "pyrition.commands." .. rebuild_camel_case(name, ".")

	if command_haystack then duplex.Insert(command_haystack, command_signature)
	else self.CommandHaystack[name] = {command_signature, [command_signature] = 1} end

	self.CommandRegistry[command_signature] = command_table

	if SERVER then self:NetAddEnumeratedString("CommandSignature", command_signature) end

	return command_table
end

PYRITION:GlobalHookCreate("CommandRegister")
