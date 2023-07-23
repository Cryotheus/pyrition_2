--https://github.com/Cryotheus/cryotheums_loader
--going to use this when ready
local config = {
	{ --methods table and loader
		global = {
			shared = true,
		},

		loader = "download",
	},

	{ --global component and modules
		client = true,
		font = "client",

		global = {
			enumerations = "shared",
			hook = "shared",
			server = true,
		},

		modules = {
			duplex = "shared",
			language = "server",
			math = "shared",
		},

		server = true,
		shared = true,
	},

	{ --dependency free files
		classes = {
			nav_area = "server",
			path_follower = "server",
			vector = "shared",
		},

		command = {
			argument = "shared",
			client = true,
		},

		download = "shared",
		fonts = "client",

		gfx = {
			material_design = "client",
		},

		hibernate = "server",
		html = "shared",

		hud = {
			declutter = {
				blocks = "client",
				crosshair = "client",
			},
		},

		net = {
			shared = true,
		},

		panels = {
			command_argument = {"client",
				integer = "client",
			},

			command_palette = {"client",
				card = "client",
				card_command = "client",
				card_command_entry = "client",
				card_command_signatures = "client",
				card_commands = "client",
				card_options = "client",
				card_simple_options = "client",
				stage = "client",
			},

			emergency_exit = "client",
			labeled_slider = "client",
			slider = "client",
		},

		player = {
			credation = "shared",
			find = "shared",

			identity = {
				client = true,
			},

			kick = "server",
			landing = "server",

			message = {
				client = true,
			},

			meta = {
				client = true,
				server = true,
				shared = true,
			},

			slap = "server",

			storage = {
				shared = true,
			},
		},

		spawnmenu = {
			client = true,
		},

		sql = {
			server = true,
		},

		time = "shared",

		wiki = {
			"shared developer",
		},
	},

	{
		command = {
			arguments = {
				integer = "shared",
				player = "shared",
			},

			shared = true,
		},

		navigation = "server",

		net = {
			client = true,
			debug = "client",
			server = true,
		},

		player = {
			message = {
				server = true,
			},

			storage = {
				client = true,
				server = true,
			},

			teleport = {
				shared = true,
			}
		},
	},

	{ --net stream & language
		command = {
			commands = {
				heal = "server",
				health = "server",
			},
		},

		language = {
			debug = "shared",
			client = true,
			shared = true,
			server = true,
		},

		net = {
			stream = {
				client = true,
				shared = true,
			},
		},

		player = {
			identity = {
				server = true,
			},

			teleport = {
				client = true,
				server = true,
			},

			time = {
				client = true,
				server = true,
			},
		}
	},

	{ --net stream model
		map = {
			shared = true,
		},

		net = {
			stream = {
				debug = "client",

				model = {
					shared = true,
				},

				server = true,
			},
		},

		player = {
			badge = {
				shared = true,
				server = true,
			},

			time = {
				shared = true,
			},
		},
	},

	{
		map = {
			client = true,
			server = true,
		},

		net = {
			stream = {
				model = {
					client = true,
					server = true,
				},
			},
		},

		player = {
			badge = {
				client = true,
			},
		},
	},

	{ --stream model registration
		--starting from this load order, all net functionality is available
		command = {
			streams = {
				execute = "shared",
				register = "shared",
			},
		},

		language = {
			stream = "shared",
		},

		map = {
			stream = "shared",
		},

		net = {
			enumeration_bits = "shared",
		},

		player = {
			badge = {
				stream = "shared",
			},

			badges = {
				anniversary = "shared",
				bot = "shared",
				killer = "shared",
				pyrition_contributor = "shared",
				pyrition_developer = "shared",
				rosette = "shared",
				victim = "shared",
			},

			storage = {
				stream = "shared",
			},

			teleport = {
				stream = "shared",
			},
		},
	},

	{global = {hooks = "shared"}} --this should always be the last script included
}

local branding = "Pyrition"
local color = Color(255, 128, 64) --color representing your project
local color_generic = Color(240, 240, 240) --most frequently used color
local load_extensions = true
local silent = CLIENT --disable console messages

do --do not touch
	--locals
	local active_gamemode = engine.ActiveGamemode()
	local block_developer = not GetConVar("developer"):GetBool()
	local check_words, load_late, load_methods, word_methods
	local extension_list = {}
	local global = _G["CryotheumsLoader_" .. branding] or {}
	local hook_name = "CryotheumsLoader" .. branding
	local include_list = {}
	local loader = debug.getinfo(1, "S").short_src
	local loader_directory = string.GetPathFromFilename(string.sub(loader, select(2, string.find(loader, GM and "/.-/gamemodes/" or "/?lua/")) + 1))
	local workshop_ids = {}

	--local functions
	local function build_list(include_list, prefix, tree) --recursively explores to build load order
		for name, object in pairs(tree) do
			local trimmed_path

			if name == 1 then
				name = select(3, string.find(prefix, "[/]*([^/]-)/?$"))
				trimmed_path = string.sub(prefix, 1, -2)
			else trimmed_path = prefix .. name end

			if istable(object) then build_list(include_list, trimmed_path .. "/", object)
			elseif object then
				local words = isstring(object) and string.Split(object, " ") or {name}
				local script = trimmed_path .. ".lua"
				local word = table.remove(words, 1)
				local load_method = load_methods[word]

				if load_method and (load_method == true or load_method(script)) and check_words(words, script) then table.insert(include_list, script) end
			end
		end
	end

	function check_words(words, script)
		for index, raw_word in ipairs(words) do
			local word_parts = string.Split(raw_word, ":")
			local word = table.remove(word_parts, 1)
			local word_method = word_methods[word] or nil

			if word_method and (word_method == true or word_method(words, script, unpack(word_parts))) then return false end
		end

		return true
	end

	local function create_hook(hook_event, script, repeated)
		global[hook_event] = {{script, repeated}, First = true}

		hook.Add(hook_event, hook_name, function() load_late(hook_event) end)
	end

	local function grab_extensions(directory)
		local files, folders = file.Find(directory .. "*", "LUA")

		if files then
			for index, folder_name in ipairs(folders) do
				local directory = directory .. folder_name .. "/"
				local files = file.Find(directory .. "*.lua", "LUA")

				if files then
					for index, file_name in ipairs(files) do
						if _G[string.upper(string.sub(file_name, 1, -5))] then
							--added the file if a global in all uppers of its name exists
							--client.lua will be loaded on the client because of the CLIENT variable
							--server.lua works just as you expect, and shared.lua works because we make the global
							table.insert(extension_list, directory .. file_name)
						end
					end
				end
			end

			for index, file_name in ipairs(files) do table.insert(extension_list, directory .. file_name) end
		end
	end

	function load_late(hook_event)
		local scripts = global[hook_event]

		--lazy load wizardry
		if scripts.First then
			local new_scripts = {}
			global[hook_event] = new_scripts
			scripts.First = false

			for index, script_pair in ipairs(scripts) do
				local script = script_pair[1]

				include(loader_directory .. script)

				if script_pair[2] then table.insert(new_scripts, script) end
			end

			--stop if we have scripts that load on repeated calls
			if new_scripts[1] then return end

			hook.Remove(hook_event, hook_name)
		else for index, script in ipairs(scripts) do include(loader_directory .. script) end end
	end

	local function load_scripts(include_list)
		--to allow detours to have some hope of working properly, we only just now cache MsgC
		local MsgC = silent and function() end or MsgC

		if GM then MsgC(color, "\nLoading " .. branding .. " (Gamemode) scripts...\n")
		else MsgC(color, "\nLoading " .. branding .. " scripts...\n") end

		MsgC(color_generic, "This load is running in the " .. (SERVER and "SERVER" or "CLIENT") .. " realm.\n")

		for index, script in ipairs(include_list) do
			MsgC(color_generic, "\t" .. index .. ": " .. script .. "\n")
			include(script)
		end

		MsgC(color, GM and "Gamemode load concluded.\n\n" or "Load concluded.\n\n")
	end

	--local tables
	load_methods = SERVER and {
		client = AddCSLuaFile,
		download = AddCSLuaFile,
		server = true,

		shared = function(script)
			AddCSLuaFile(script)

			return true
		end
	} or {client = true, shared = true}

	word_methods = { --return true to block the script
		dedicated = not game.IsDedicated(),
		developer = block_developer,
		hosted = not game.IsDedicated() and game.SinglePlayer(),
		if_addon = function(_words, _script, workshop_id) return not workshop_ids[workshop_id] end,
		if_gamemode = function(_words, _script, name) return active_gamemode ~= name end,
		if_global = function(_words, _script, global_name) return _G[global_name] == nil end,
		listen = game.IsDedicated() or game.SinglePlayer(),
		no_addon = function(_words, _script, workshop_id) return workshop_ids[workshop_id] end,
		no_gamemode = function(_words, _script, name) return active_gamemode == name end,
		no_global = function(_words, _script, global_name) return _G[global_name] ~= nil end,
		simple = game.IsDedicated(),
		single = not game.SinglePlayer(),

		await = function(_words, script, hook_event)
			if _CryotheumsLoaderHookHistory[hook_event] then return true end

			local scripts = global[hook_event]

			if scripts then table.insert(scripts, {script, false})
			else create_hook(hook_event, script, false) end

			return false
		end,

		gamemode = function(_words, script)
			if _CryotheumsLoaderHookHistory.Initialize then return true end

			local scripts = global.Initialize

			if scripts then table.insert(scripts, {script, false})
			else create_hook("Initialize", script, false) end

			return false
		end,

		hook = function(_words, script, hook_event)
			local scripts = global[hook_event]

			if _CryotheumsLoaderHookHistory[hook_event] then
				if scripts then table.insert(scripts, script)
				else global[hook_event] = {script} end
			else
				if scripts then table.insert(scripts, {script, true})
				else create_hook(hook_event, script, true) end
			end

			--only ever run by the hook
			return true
		end,

		player = function(_words, script)
			if _CryotheumsLoaderHookHistory.PlayerInitialSpawn then return true end

			local scripts = global.PlayerInitialSpawn

			if scripts then table.insert(scripts, {script, false})
			else create_hook("PlayerInitialSpawn", script, false) end

			return false
		end,

		world = function(_words, script)
			if _CryotheumsLoaderHookHistory.InitPostEntity then return true end

			local scripts = global.InitPostEntity

			if scripts then table.insert(scripts, {script, false})
			else create_hook("InitPostEntity", script, false) end

			return false
		end,
	}

	--globals
	_CryotheumsLoaderHookHistory = _CryotheumsLoaderHookHistory or {}
	_G["CryotheumsLoader_" .. branding] = global

	--post
	if load_extensions then
		local loader_extensions_directory = loader_directory .. "extensions/"
		local map = game.GetMap()
		SHARED = true --for shared.lua extension files

		grab_extensions(loader_extensions_directory)
		grab_extensions(loader_extensions_directory .. "gamemode/" .. active_gamemode .. "/")
		grab_extensions(loader_extensions_directory .. "map/" .. map .. "/")
		table.sort(extension_list)
	end

	local function contains_path_list(file_structure, path_list)
		local indexed = file_structure

		for index, object in ipairs(path_list) do
			indexed = indexed[object]

			if not indexed then return false end
		end

		return not indexed or indexed[1]
	end

	local function find_path(path)
		local path_list = string.Split(path, "/")

		for index, file_structure in ipairs(config) do if contains_path_list(file_structure, path_list) then return index end end

		return false
	end

	--give access to the config to extensions
	CryotheumsLoaderActiveConfig = config

	--provide useful functions
	CryotheumsLoaderFunctions = {
		After = function(path, dont_create_table)
			local index = find_path(path)

			if index then
				local next_structure = config[index + 1]

				if next_structure then return next_structure, index + 1, false end
				if dont_create_table then return nil, index + 1, false end

				next_structure = {}

				return next_structure, table.insert(config, next_structure), true
			else index = #config end

			return config[index], index, false
		end,

		Before = function(path, dont_create_table)
			local index = find_path(path)
			local found = false

			if index == 1 then found = true
			elseif index then return config[index - 1], index - 1, false end
			if dont_create_table then return nil, index or 1, false end

			local first_structure = {}

			table.insert(config, 1, first_structure)

			return first_structure, 1, found
		end
	}

	--load the extensions
	for index, value in ipairs(extension_list) do include(value) end

	CryotheumsLoaderActiveConfig = nil
	CryotheumsLoaderFunctions = nil

	for hook_event, hook_functions in pairs(hook.GetTable()) do if hook_functions[hook_name] then hook.Remove(hook_event, hook_name) end end --remove outdated hooks
	for index, addon in ipairs(engine.GetAddons()) do workshop_ids[addon.wsid] = true end --build the workshop id list
	for priority, tree in ipairs(config) do build_list(include_list, "", tree) end --build the load order

	load_scripts(include_list, false)
end