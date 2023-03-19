--locals
local addon_name = "pyrition"
local command_prefix = SERVER and "sv_" or "cl_"
local function_table = PYRITION
local hook_prefix = "Pyrition"
local output_path = "pyrition_2.wiki/generated"
local link_prefix = "https://github.com/Cryotheus/pyrition_2/blob/main/lua/"

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

					print("yep", key)

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
	local current_prefix
	local details_collection = {}
	local documentation = {}
	local files = file.Find(output_path .. "/_details_*.json", "DATA")

	if not files then error("No details collected!") end

	for index, file_name in ipairs(files) do
		local environment_signature = string.sub("_details_client_listen.json", 10, -6)
		local json = util.JSONToTable(file.Read(output_path .. "/" .. file_name, "DATA"))
		local realm, host_method = string.Split(environment_signature, "_")
		
		print(index, file_name)

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

	print("prefix", current_prefix)

	for key, details in pairs(details_collection) do
		local current_line, current_line_end, current_source
		--local trimmed_source = string.sub(details.Source, trim_prefix)
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

				if documentation[trimmed_source] then table.insert(documentation[trimmed_source], information)
				else documentation[trimmed_source] = {information} end

				table.insert(environments, environment_signature)
				table.insert(variants, information)
			end
		end
	end

	for trimmed_source, information in pairs(documentation) do
		--local component_name = string.gsub(trimmed_source, "/", "")
		local script = file.Read(current_prefix .. trimmed_source, "LUA")
		local script_lines = script and string.Split(script, "\n")

		print(script_lines and #script_lines or "invalid")
		print(trimmed_source, string.GetPathFromFilename(trimmed_source))
		print("line:", script_lines and script_lines[information.Line])
		PrintTable(information)

		break
		--file.Write(file_path, file.Read(trimmed_source, "GAME"))
	end
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
	ConsoleCommandArgumentGetSettingMacro:
		activelines:
			34	=	true
			36	=	true
		currentline	=	-1
		func	=	function: 0x01117e197918
		isvararg	=	false
		lastlinedefined	=	37
		linedefined	=	33
		nparams	=	2
		nups	=	0
		short_src	=	addons/pyrition/lua/pyrition/console/command_argument.lua
		source	=	@addons/pyrition/lua/pyrition/console/command_argument.lua
		what	=	Lua
	ConsoleCommandArgumentParse:
		activelines:
			40	=	true
			41	=	true
			43	=	true
			44	=	true
			45	=	true
			46	=	true
			48	=	true
			50	=	true
			52	=	true
			54	=	true
			55	=	true
			56	=	true
			58	=	true
			60	=	true
			61	=	true
			64	=	true
			65	=	true
			67	=	true
			69	=	true
		currentline	=	-1
		func	=	function: 0x011184315a58
		isvararg	=	false
		lastlinedefined	=	70
		linedefined	=	39
		nparams	=	2
		nups	=	1
		short_src	=	addons/pyrition/lua/pyrition/console/command_argument.lua
		source	=	@addons/pyrition/lua/pyrition/console/command_argument.lua
		what	=	Lua
]]
