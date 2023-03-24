---DEVELOPER
--locals
command_prefix = SERVER and "sv_pyrition_wikify_" or "cl_pyrition_wikify_"

include("includes/entity_proxy.lua")
print("hi!")

--local functions
local function best_match(hay_stack, pattern_start, patterns)
	local best_index
	local best_capture
	local best_start = math.huge
	local best_finish

	for index, pattern in ipairs(patterns) do
		local start, finish, capture = string.find(hay_stack, pattern, pattern_start)

		if start == best_start then
			if finish > best_finish then
				best_capture = capture
				best_finish = finish
				best_index = index
			end
		elseif start and start < best_start then
			best_capture = capture
			best_finish = finish
			best_index = index
			best_start = start
		end
	end

	if best_index then return best_start, best_finish, best_index, best_capture end
end

local function collect_functions(hashed, collection)
	for key, value in pairs(hashed) do
		if isstring(key) and isfunction(value) then
			table.insert(collection, value)
		end
	end

	return collection
end

local function _common_prefix(alpha, bravo)
	local finish = #alpha

	for index = 1, finish do
		if alpha[index] ~= bravo[index] then
			finish = index - 1

			break
		end
	end

	return string.sub(alpha, 1, finish)
end

local function _get_nested(tree, indexing)
	for index, key in ipairs(indexing) do
		local branch = tree[key]

		if branch then tree = branch
		else
			branch = {}
			tree[key] = branch
			tree = branch
		end
	end

	return tree
end

local function indicative_case(text) return string.lower(string.gsub(text, "%u", "^%1")) end

local function multiple_gmatch(hay_stack, start, ...)
	local march = start
	local patterns
	local reset = 1
	local returns = {}

	if istable(...) then patterns = ...
	else patterns = {...} end

	for index in ipairs(patterns) do returns[index] = false end

	return function()
		local best_start, best_finish, best_index, best_capture = best_match(hay_stack, march, patterns)
		returns[reset] = false

		if best_start then
			march = best_finish + 1
			reset = best_index
			returns[best_index] = best_capture or string.sub(hay_stack, best_start, best_finish)

			return unpack(returns)
		end
	end
end

local function _print_long(text)
	for march = 1, #text, 200 do MsgC(color_white, string.sub(text, march, march + 199)) end

	MsgC("\n")
end

local function recursive_delete(path)
	local files, folders = file.Find(path .. "/*", "DATA")

	--no need to delete what doesn't exist
	if not files then return end

	for index, file_name in ipairs(files) do file.Delete(path .. file_name) end
	for index, folder_name in ipairs(folders) do recursive_delete(path .. folder_name) end

	file.Delete(path)
end

--pyrition functions
function PYRITION:Wikify()
	local default_pattern = "pyrition/.+%.lua"
	local filtered = {}

	local pyrition = {
		Category = PYRITION_WIKIFY_GLOBALS,
		Name = "pyrition",
		Owner = "Pyrition",
		Parent = "PYRITION",
		SourcePattern = "pyrition/",
	}

	local pyrition_hooks = {
		Category = PYRITION_WIKIFY_HOOKS,
		Name = "pyrition_hooks",
		Owner = "Pyrition",
		Parent = "PYRITION",
		SourcePattern = "pyrition/",
	}

	file.CreateDir("pyrition/wikify/pages")

	for key, value in pairs(self) do if isstring(key) and isfunction(value) then table.insert(filtered, key) end end

	for index, key in pairs(filtered) do
		if not string.StartWith(key, "Pyrition") then
			local hook_key = "Pyrition" .. key

			if isfunction(self[hook_key]) then table.insert(pyrition_hooks, self[hook_key])
			else table.insert(pyrition, self[key]) end
		elseif isfunction(self[key]) then table.insert(pyrition_hooks, self[key]) end
	end

	self:WikifyCollectFunctions(pyrition)
	self:WikifyCollectFunctions(pyrition_hooks)

	if entity_proxy then
		self:WikifyCollectFunctions(collect_functions(entity_proxy, {
			Category = PYRITION_WIKIFY_LIBRARIES,
			Name = "entity_proxy",
			Owner = "Networking Entity Proxy Module",
			Parent = "entity_proxy",
		}))
	end

	self:WikifyCollectFunctions(collect_functions(duplex, {
		Category = PYRITION_WIKIFY_LIBRARIES,
		Name = "pyrition_duplex",
		Owner = "Pyrition",
		Parent = "duplex",
		SourcePattern = "pyrition/modules/duplex%.lua$",
	}))

	self:WikifyCollectFunctions(collect_functions(math, {
		Category = PYRITION_WIKIFY_LIBRARIES,
		Name = "pyrition_math",
		Owner = "Pyrition",
		Parent = "math",
		SourcePattern = "pyrition/modules/math%.lua$",
	}))

	self:WikifyCollectFunctions(collect_functions(FindMetaTable("Vector"), {
		Category = PYRITION_WIKIFY_CLASSES,
		Name = "Vector",
		Owner = "Pyrition",
		Parent = "Vector",
		SourcePattern = default_pattern,
	}))

	self:WikifyCollectFunctions(collect_functions(FindMetaTable("Player"), {
		Category = PYRITION_WIKIFY_CLASSES,
		Name = "Player",
		Owner = "Pyrition",
		Parent = "Player",
		SourcePattern = default_pattern,
	}))
end

function PYRITION:WikifyCollectFunctions(function_list)
	local file_line_positions = {}
	local files_read = {}
	local source_pattern = function_list.SourcePattern

	for index = #function_list, 1, -1 do
		local info = debug.getinfo(function_list[index], "S")
		local source = info.short_src

		if info.what == "Lua" and (not source_pattern or string.find(source, source_pattern)) then
			local comments = {}
			local script_lines = file_line_positions[source]
			local script = files_read[source]

			--read the file if it hasn't been read yet
			if not script then
				script = file.Read(source, "GAME")
				script_lines = {}
				file_line_positions[source] = script_lines
				files_read[source] = script

				local march = 1
				local script_length = #script
				--string.find(script, "\r?\n", found_finish)

				while true do
					found_start, found_finish = string.find(script, "\r?\n", march)

					if not found_start then break end

					table.insert(script_lines, {
						march,
						found_start - 1,
					})

					march = found_finish + 1
				end

				if march < script_length then table.insert(script_lines, {march, script_length}) end
			end

			local end_line = info.lastlinedefined
			local start_line = info.linedefined
			local code = string.sub(script, script_lines[start_line][1], script_lines[end_line][2]) .. "\n"
			local name = table.remove(string.Split(table.remove(string.Split(select(3, string.find(code, "%s*function%s+(.-)%s*%(.-\n")), ".")), ":"))

			if name then
				print("name", name)
				for line_comment, block_comment in multiple_gmatch(code, 1, "%-%-%-(.-)\r?\n", "%-%-%[%[%-%s*(.-)%]%]", "%b''", "%b\"\"") do
					local comment = line_comment or block_comment

					if comment then table.insert(comments, line_comment) end
				end

				function_list[index] = {
					Comments = next(comments) and comments,
					Line = start_line,
					LineEnd = end_line,
					Name = name,
					Source = source,
				}
			else table.remove(function_list, index) end
		else table.remove(function_list, index) end
	end

	table.Empty(files_read)

	if not function_list[1] then return end

	file.Write(
		string.lower("pyrition/wikify/" .. (SERVER and "server_function_" or "client_function_") .. (function_list.Name or "list") .. ".json"),
		util.TableToJSON(function_list)
	)
end

function PYRITION:WikifyGenerate()
	local collection_files = file.Find("pyrition/wikify/*", "DATA")

	if not collection_files then return false, "No collections found" end

	local function_registry = {}
	local root_path = "pyrition/wikify/pages/"

	file.CreateDir(string.TrimRight(root_path, "/"))

	--create a list of all functions
	for collection_index, collection_file in ipairs(collection_files) do
		local json = util.JSONToTable(file.Read("pyrition/wikify/" .. collection_file, "DATA"))

		local category = json.Category
		local owner = json.Owner
		local parent = json.Parent
		local realm = select(3, string.find(collection_file, "(.-)_"))
		local signature_prefix = (json.Signature or parent or owner)

		for index, info in ipairs(json) do
			local signature = signature_prefix .. "~" .. info.Name .. "~" .. info.Line .. "~" .. info.LineEnd
			local registered = function_registry[signature]

			if not registered then
				registered = {
					Category = category,
					Comments = info.Comments,
					Name = info.Name,
					Owner = owner,
					Parent = parent,
					Tags = {},
				}

				--info.Category
				--info.Owner
				--info.Parent

				function_registry[signature] = registered
			end

			registered.Tags[realm == "client" and "c" or "s"] = true
		end
	end

	for signature, info in pairs(function_registry) do
		local category = info.Category
		local comments = info.Comments
		local function_name = info.Name
		local name = function_name
		local owner = info.Owner
		local parent = info.Parent
		local tag_list = {}

		for tag in pairs(info.Tags) do table.insert(tag_list, tag) end

		if tag_list then
			table.sort(tag_list)

			name = table.concat(tag_list, "") .. "-" .. name
		end

		local contents = "# " .. function_name .. "\n" .. (comments and table.concat(comments, "\n") or "No documentation available.")
		local prefix = owner .. "/" .. category .. "/" .. (parent and parent .. "/" or "/")
		local path = indicative_case(prefix .. name .. ".txt")

		print(root_path .. path)
		file.CreateDir(root_path .. string.GetPathFromFilename(path))
		file.Write(root_path .. path, contents)
	end
end

--post
concommand.Add(SERVER and "sv_pyrition_wikify" or "cl_pyrition_wikify", function(ply)
	if SERVER and ply:IsValid() and not ply:IsListenServerHost() then return end

	PYRITION:Wikify()
end)

if CLIENT then concommand.Add("cl_pyrition_wikify_generate", function() PYRITION:WikifyGenerate() end) end