--locals
local addon_name = "pyrition"
local command_prefix = SERVER and "sv_" or "cl_"
local function_table = PYRITION
local hook_prefix = "Pyrition"
local output_path = "pyrition_2.wiki/generated"
local link_prefix = "https://github.com/Cryotheus/pyrition_2/blob/main/lua/"

--local tables
local ignore_in_component = {
	client = true,
	server = true,
	shared = true,
}

--local functions
local function common_prefix(alpha, bravo)
	local finish = #alpha

	for index = 1, finish do
		if alpha[index] ~= bravo[index] then
			finish = index - 1

			break
		end
	end

	return string.sub(alpha, 1, finish)
end

local function _find_function_table_name(function_table)
	--search deeper?
	for key, value in pairs(_G) do if value == function_table then return key end end
end

local function get_nested(tree, indexing)
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

local function recursive_delete(path)
	local files, folders = file.Find(path .. "/*", "DATA")

	--no need to delete what doesn't exist
	if not files then return end

	for index, file_name in ipairs(files) do file.Delete(path .. file_name) end
	for index, folder_name in ipairs(folders) do recursive_delete(path .. folder_name) end

	file.Delete(path)
end

--pyrition functions
function PYRITION:WikiCollect()
	---Disgusting code to collect information about the methods available in the current realm.
	file.CreateDir(output_path)

	local realm_details = {}
	local output_path = output_path .. "/"

	for key, value in pairs(function_table) do
		if isstring(key) and isfunction(value) and not string.StartWith(key, hook_prefix) then
			local info = debug.getinfo(value, "flLSu")

			if info.what == "Lua" then
				local source = info.short_src
				local source_start, source_boiler = string.find(source, "addons/.-/lua/")

				if source_start and string.sub(string.sub(source, source_start, source_boiler), 8, -6) == addon_name then
					local line = info.linedefined
					local line_end = info.lastlinedefined

					local details = {
						Hooked = function_table[hook_prefix .. key] and true or nil,
						Line = line,
						LineEnd = line_end,
						Source = string.sub(source, source_boiler + 1)
					}

					realm_details[key] = details
					--ErrorNoHalt("failed to document " .. key .. "\n" .. source .. "\n")
				end
			end
		end
	end

	file.Write(
		output_path .. "_details_"
		.. (SERVER and "server_" or "client_")
		.. (game.SinglePlayer() and "single" or game.IsDedicated() and "dedicated" or "listen")
		.. ".json",

		util.TableToJSON(realm_details)
	)
end

function PYRITION:WikiGenerate()
	---Somehow even more disgusting code to generate a wiki from the collected information.
	local current_prefix
	local details_collection = {}
	local documentation = {}
	local files = file.Find(output_path .. "/_details_*.json", "DATA")
	local structure = {}

	if not files then error("No details collected!") end

	for index, file_name in ipairs(files) do
		local environment_signature = string.sub(file_name, 10, -6)
		local json = util.JSONToTable(file.Read(output_path .. "/" .. file_name, "DATA"))
		local realm, host_method = string.Split(environment_signature, "_")
		
		for key, details in pairs(json) do
			local existing = details_collection[key]
			local source = details.Source
			current_prefix = current_prefix and common_prefix(current_prefix, source) or source

			if not existing then
				existing = {
					Hooked = details.Hooked,
					SignedDetails = {}
				}

				details_collection[key] = existing
			end

			existing.SignedDetails[environment_signature] = {
				HostMethod = host_method,
				Line = details.Line,
				LineEnd = details.LineEnd,
				Realm = realm,
				Source = source,
			}
		end
	end

	local trim_prefix = #current_prefix + 1

	for key, details in pairs(details_collection) do
		local current_line, current_line_end, current_source
		local environments
		local variants = {}

		for environment_signature, signed_details in pairs(details.SignedDetails) do
			local line, line_end, source = signed_details.Line, signed_details.LineEnd, signed_details.Source

			if current_line ~= line or current_line_end ~= line_end or source ~= current_source then
				current_line = line
				current_line_end = line_end
				environments = {}
				current_source = source
				local trimmed_source = string.sub(source, trim_prefix)

				local information = {
					Environments = environments,
					Line = line,
					LineEnd = line_end,
					Link = link_prefix .. source .. "#L" .. line .. "-L" .. line_end,
					Source = source,
				}

				local component_docs = documentation[trimmed_source]

				if not component_docs then
					component_docs = {}
					documentation[trimmed_source] = component_docs
				end

				if component_docs[key] then table.insert(component_docs[key], information)
				else component_docs[key] = {information} end

				table.insert(variants, information)
			end

			table.insert(environments, environment_signature)
		end
	end

	for trimmed_source, methods in pairs(documentation) do
		local component_indexing = string.Split(string.sub(trimmed_source, 1, -5), "/")
		local component_name = string.sub(string.gsub(trimmed_source, "/", ""), 1, -5)
		local order = {}
		local script = file.Read(current_prefix .. trimmed_source, "LUA")
		local script_lines = script and string.Split(script, "\n")

		local last_component = component_indexing[#component_indexing]

		--remove client, server, and shared endings from component names
		if ignore_in_component[last_component] then
			component_name = string.sub(component_name, 1, -1 - #last_component)

			table.remove(component_indexing)
		end

		local tree = get_nested(structure, component_indexing)

		for key in pairs(methods) do table.insert(order, key) end

		for order_index, key in ipairs(order) do
			local common_text = common_prefix(component_name, string.lower(key))
			local method_name = string.sub(key, #common_text + 1)
			local method_parent = string.sub(key, 1, #common_text)

			--print("component_indexing", component_name, unpack(component_indexing))
			local file_path = table.concat(component_indexing, "/")
			local meta_data = {
				FilePath = file_path .. ".txt",
				ParentComponenet = method_parent,
				FriendlyName = table.concat(component_indexing, "-")
			}

			meta_data.Path = string.sub(file_path, 1, -1 - #component_indexing[#component_indexing])
			tree[0] = meta_data

			for variant_index, details in ipairs(methods[key]) do
				local mark_down = ""

				for line_index = details.Line, details.LineEnd do
					local line = script_lines[line_index]
					local wiki_comment = string.find(line, "%-%-%-")

					if wiki_comment then mark_down = mark_down .. string.sub(line, wiki_comment + 3) .. "\n" end
				end

				--script_lines
				local data = {
					Line = details.Line,
					LineEnd = details.LineEnd,
					Link = details.Link,
					MarkDown = mark_down ~= "" and string.sub(mark_down, 1, -2) or nil,
					Name = method_name,
				}

				for index, environment_signature in ipairs(details.Environments) do
					if string.StartWith(environment_signature, "client_") then data.Client = true
					elseif string.StartWith(environment_signature, "server_") then data.Server = true end
				end

				table.insert(tree, data)
			end
		end
	end
	
	local function write_files(tree)
		local meta_data = tree[0]
		--tree[0] = nil

		if meta_data then
			--local file_path = meta_data.FilePath
			local parent_component = meta_data.ParentComponenet
			--local path = meta_data.Path

			local mark_down = "# " .. parent_component .. "\nThis page is automatically generated. Generated pages are still in beta and will change drastically as the generator is improved.\n"

			--print("parent_component", parent_component)

			for index, method_details in ipairs(tree) do
				--tree[index] = nil
				local icon

				if method_details.Client and method_details.Server then icon = "shared"
				elseif method_details.Client then icon = "client"
				elseif method_details.Server then icon = "server" end 

				if icon then icon = "![" .. icon .. "](https://raw.githubusercontent.com/Cryotheus/pyrition_2/main/.github/WIKI/" .. icon .. ".png) "
				else icon = "" end

				mark_down = mark_down .. "## " .. icon .. "[" .. method_details.Name .. "](" .. method_details.Link .. ")\n"

				if method_details.MarkDown then mark_down = mark_down .. method_details.MarkDown end

				mark_down = mark_down .. "\n"
			end

			file.Write(output_path .. "/g-" .. meta_data.FriendlyName .. ".txt", mark_down)
		end

		for key, value in pairs(tree) do
			if not isnumber(key) then write_files(value) end
		end
	end

	--PrintTable(structure)
	write_files(structure)
end

--commands
concommand.Add(command_prefix .. "pyrition_wiki_collect", function(ply)
	if SERVER and ply:IsValid() and not ply:IsListenServerHost() then return end

	PYRITION:WikiCollect()
end)

concommand.Add(command_prefix .. "pyrition_wiki_generate", function(ply)
	if SERVER and ply:IsValid() and not ply:IsListenServerHost() then return end

	PYRITION:WikiGenerate()
end)

concommand.Add(command_prefix .. "pyrition_wiki_purge", function(ply)
	if SERVER and ply:IsValid() and not ply:IsListenServerHost() then return end

	recursive_delete(output_path)
end)

--[[
	console:
		1:
			Client	=	true
			Line	=	20
			LineEnd	=	43
			Link	=	https://github.com/Cryotheus/pyrition_2/blob/main/lua/pyrition/console/shared.lua#L20-L43
			Name	=	ParseArguments
			Server	=	true
		2:
			Client	=	true
			Line	=	45
			LineEnd	=	72
			Link	=	https://github.com/Cryotheus/pyrition_2/blob/main/lua/pyrition/console/shared.lua#L45-L72
			Name	=	ParseString
			Server	=	true
		command:
			1:
				Client	=	true
				Line	=	27
				LineEnd	=	42
				Link	=	https://github.com/Cryotheus/pyrition_2/blob/main/lua/pyrition/console/command.lua#L27-L42
				Name	=	SignatureTreeSet
				Server	=	true
]]
