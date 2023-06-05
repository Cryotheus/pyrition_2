--locals
local rebuild_camel_case = PYRITION._RebuildCamelCase

--local functions
function finds_sorter(alpha, bravo)
	local alpha_score, bravo_score = alpha[3], bravo[3]

	--same score? alphabetically sort string
	if alpha_score == bravo_score then return alpha[1] < bravo[1] end

	return alpha_score > bravo_score
end

--globals
PYRITION.CommandHaystack = PYRITION.CommandHaystack or {}
PYRITION.CommandHaystackCache = PYRITION.CommandHaystackCache or {}
PYRITION.CommandLastHaystackNeedle = PYRITION.CommandLastHaystackNeedle or {}
PYRITION.CommandRegistry = PYRITION.CommandRegistry or {}

--[[
PYRITION:ConsoleCommandRegister("heal", {
	Arguments = {"Player Default"},
	Console = true,

	Execute = function(ply, targets)
]]

--pyrition functions
function PYRITION:Command(command_signature, arguments)

end

function PYRITION:CommandClearHaystackCache(namespace)
	self.CommandHaystackCache[namespace] = nil
	self.CommandLastHaystackNeedle[namespace] = nil
end

function PYRITION:CommandCreateSignature(command_table)

end

function PYRITION:CommandFindSignatures(needle, namespace)
	local finds = {}

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
			if key == needle then table.insert(finds, {key, signatures, 100})
			elseif string.StartsWith(key, needle) then table.insert(finds, {key, signatures, 50})
			else table.insert(removals, key) end
		end

		for index, key in ipairs(removals) do haystack[key] = nil end
	else --simple search
		for key, signatures in pairs(self.CommandHaystack) do
			if key == needle then table.insert(finds, {key, signatures, 100})
			elseif string.StartsWith(key, needle) then table.insert(finds, {key, signatures, 50})  end
		end
	end

	table.sort(finds, finds_sorter)

	return finds
end

function PYRITION:HOOK_CommandRegister(name, command_table)
	assert(not string.find(name, "%s"), "CommandRegister cannot accept a name with whitespace.")
	assert(string.find(name, "%u") and not string.find(name, "[^%a%d]"), "CommandRegister cannot accept a name that is not CamelCase (digits allowed).")

	--"soft" update for the command palette's cache
	if next(self.CommandHaystackCache) then table.Empty(self.CommandHaystackCache) end

	local argument_signature

	if command_table.Arguments then
		local argument_settings = command_table.Arguments
		local argument_signatures = {}

		for index, settings in ipairs(argument_settings) do
			local new_settings = self:CommandArgumentParseSettings(settings)
			argument_settings[index] = new_settings
			argument_signatures[index] = new_settings.Signature
		end

		argument_signature = table.concat(argument_signatures)
	else
		argument_signature = ""
		command_table.Arguments = {}
	end

	local command_signature = name .. "~" .. argument_signature
	command_table.LocalizationKey = "pyrition.commands." .. rebuild_camel_case(name, ".")
	command_table.Name = name
	command_table.Signature = command_signature

	self.CommandRegistry[command_signature] = command_table
end

--post
PYRITION:GlobalHookCreate("CommandRegister")