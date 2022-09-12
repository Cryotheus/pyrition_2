--Cryotheum#4096
--https://github.com/Cryotheus/preconfigured_loader
--intent: rewrite pyrition
--status: active
--motivation: whats that

local config = {
	convention = 23,	--0010 111
	duplex = 23,		--0010 111
	gradient = 23,		--0010 111
	hibernate = 26,		--0011 010
	ip = 18,			--0010 010
	loader = 4,			--0000 100
	string = 31,		--0011 111
	time = 23,			--0010 111
	
	console = {
		chat = {
			calculator = 61,	--111 101
			client = 53,		--110 101
			server = 50,		--110 010
		},
		
		command_arguments = {
			integer = 71,	--1000 111
			map = 71,		--1000 111
			number = 71,	--1000 111
			player = 71,	--1000 111
			string = 71,	--1000 111
			time = 71,		--1000 111
		},
		
		commands = {
			bring = 74,			--1001 010
			cleanup = 74,		--1001 010
			["goto"] = 74,		--1001 010
			heal = 74,			--1001 010
			health = 74,		--1001 010
			kick = 74,			--1001 010
			map = 74,			--1001 010
			message = 74,		--1001 010
			noclip = 74,		--1001 010
			respawn = 74,		--1001 010
			["return"] = 74,	--1001 010
			send = 74,			--1001 010
			slap = 74,			--1001 010
			slay = 74,			--1001 010
			sql = 74,			--1001 010
			strip = 74,			--1001 010
		},
		
		stream = {
			command = 63,	--111 111
			commands = 63,	--111 111
		},
		
		command = 63,			--111 111
		command_argument = 63,	--111 111
		server = 58,			--111 010
		shared = 55,			--110 111
	},
	
	global = {
		client = 13,	--001 101
		hook = 15,		--001 111
		server = 10,	--001 010
		shared = 7		--000 111
	},
	
	hud_declutter = {
		blocks = 37,	--100 101
		crosshair = 37,	--100 101
	},
	
	language = {
		client = 53,	--101 101
		debug = 47,		--101 111
		library = 18,	--010 010
		shared = 47,	--101 111
		server = 42,	--101 010
		stream = 55,	--110 111
	},
	
	map = {
		client = 69,	--1000 101
		shared = 63,	--0111 111
		server = 66,	--1000 010
		stream = 71,	--1000 111
	},
	
	net = {
		client = 37,			--100 101
		debug = 31,				--011 111
		enumeration_bits = 55,	--110 111
		server = 34,			--100 010
		shared = 31,			--011 111
		
		stream = {
			client = 53,	--110 101
			shared = 47,	--101 111
			server = 50,	--110 010
			
			model = {
				client = 53,	--110 101
				server = 50,	--110 010
				shared = 47,	--101 111
			}
		}
	},
	
	player = {
		find = 31,		--0011 111
		kick = 26,		--0011 010
		landing = 26,	--0011 010
		meta = 23,		--0010 111
		slap = 26,		--0011 010
		storage = 58,	--0111 010
		time = 66,		--1000 010
		
		badge = {
			server = 74,	--1001 010
			shared = 71,	--1000 111
		},
		
		badges = {
			killer = 87,				--1010 111
			pyrition_developer = 87,	--1010 111
			rosette = 87,				--1010 111
		},
		
		identity = {
			client = 21,	--0010 101
			server = 66		--1000 010
		},
		
		message = {
			client = 29,	--11 101
			server = 26,	--11 010
		},
		
		teleport = {
			client = 61,	--111 101
			server = 58,	--111 010
			shared = 55,	--110 111
			stream = 63,	--111 111
		}
	},
	
	spawnmenu = {
		client = 69,	--1000 101
	},
	
	sql = {
		client = 53,	--110 101
		server = 58,	--111 010
	}
}

--what do we say we are when we load up?
local branding = "Pyrition"

--path to the folder for merging entries into the config folder
--setting this to true is the same as setting this to "extensions"
local loader_extension_path = true

--maximum amount of folders we may go down in the configuration tree
local max_depth = 4

--set this to a string if you want a command under that name to be created for reloading the scripts 
local reload_command = false

--should the file self-include for command reloads instead of loading with the source's path as a prefix
--instead of true, you can put a string for the include function to use
local self_include_reload = true

--colors
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 128, 64)

--end of configurable variables



----not configuration variables but go ahead and change them if you know what you're doing
	local active_gamemode = engine.ActiveGamemode()
	local fl_bit_band = bit.band
	local fl_bit_rshift = bit.rshift
	local highest_priority = 0
	local load_order = {}
	
	--don't forget to shift over priority bits if you change the amount of load functions in use
	--make sure you go by powers of 2 as well
	local load_functions = {
		[1] = function(path) if CLIENT then include(path) end end,
		[2] = function(path) if SERVER then include(path) end end,
		[4] = function(path) if SERVER then AddCSLuaFile(path) end end
	}
	
	local load_function_shift = table.Count(load_functions)
	
	--directory stuff
	loader_extension_path = loader_extension_path == true and "extensions/" or loader_extension_path .. "/"
	local loader_full_source = debug.getinfo(1, "S").short_src
	local loader_path = string.sub(loader_full_source, select(2, string.find(loader_full_source, "lua/", 1, true)) + 1)
	local loader_directory = string.GetPathFromFilename(loader_path)
	local map = game.GetMap()

--local functions
local function construct_order(config_table, depth, path)
	--local tabs = " ]" .. string.rep("    ", depth)
	
	for key, value in pairs(config_table) do
		if istable(value) then
			--MsgC(color_generic, tabs .. key .. ":\n")
			
			if depth < max_depth then construct_order(value, depth + 1, path .. key .. "/")
			else MsgC(color_significant, " ]" .. string.rep("    ", depth) .. "    !!! MAX DEPTH !!!\n") end
		else
			--MsgC(color_generic, tabs .. key .. " = 0d" .. value .. "\n")
			
			local priority = fl_bit_rshift(value, load_function_shift)
			local script_path = path .. key
			
			if priority > highest_priority then highest_priority = priority end
			if load_order[priority] then load_order[priority][script_path] = fl_bit_band(value, 7)
			else load_order[priority] = {[script_path] = fl_bit_band(value, 7)} end
		end
	end
end

local function find_extensions(file_list, root_directory, directory)
	local extended_directory = root_directory .. directory
	local files = file.Find(extended_directory .. "/*", "LUA")
	
	--file.Exists is not reliable for directories on client
	if files then
		local added_configurations = false
		
		for index, file_name in ipairs(files) do
			added_configurations = true
			
			table.insert(file_list, directory .. "/" .. file_name)
		end
		
		if added_configurations then return MsgC(color_generic, " Appended ", color_significant, directory, color_generic, " extension configurations.\n") end
	end
	
	MsgC(color_generic, " No ", color_significant, directory, color_generic, " extension configurations to append.\n")
end

local function grab_extensions(extension_directory)
	--grab all files in the extension folder, these are loaded first
	local files = file.Find(extension_directory .. "*", "LUA")
	
	if files then
		find_extensions(files, extension_directory, "gamemode/" .. active_gamemode)
		find_extensions(files, extension_directory, "map/" .. map)
		
		--load all those files and merge their return if its a table
		for index, file_name in ipairs(files) do
			local file_path = extension_directory .. file_name
			local config_extension, add_for_download = include(file_path)
			
			if config_extension then table.Merge(config, config_extension) end
			if add_for_download and SERVER then MsgC(color_generic, " ]    SHARED	", color_significant, string.GetPathFromFilename(file_name), color_generic, string.GetFileFromFilename(file_name) .. "\n")
			else MsgC(color_generic, CLIENT and " ]    SHARED	" or " ]    SERVER	", color_significant, string.GetPathFromFilename(file_name), color_generic, string.GetFileFromFilename(file_name) .. "\n") continue end
			
			AddCSLuaFile(file_path)
		end
	else MsgC(color_significant, "No extension folder.\nThis is not an error, the path used for extensions does not exist most likely meaning all extensions are third party.\n") end
end

local function load_by_order(prefix_directory)
	for priority = 0, highest_priority do
		local script_paths = load_order[priority]
		
		if script_paths then
			if priority == 0 then MsgC(color_generic, " Loading scripts at level 0...\n")
			else MsgC(color_generic, "\n Loading scripts at level " .. priority .. "...\n") end
			
			for script_path, bits in pairs(script_paths) do
				local script_path_extension = script_path .. ".lua"
				
				MsgC(color_generic, " ]    0d" .. bits .. "	" .. script_path_extension .. "\n")
				
				for bit_flag, func in pairs(load_functions) do if fl_bit_band(bits, bit_flag) > 0 then func(prefix_directory .. script_path_extension) end end
			end
		else MsgC(color_significant, "\nSkipping level " .. priority .. " as it contains no scripts.\n") end
	end
end

local function load_scripts(command_reload)
	--load extensions if enabled; this will be converted into extensions/ if true
	if loader_extension_path then
		MsgC(color_generic, "\n\\\\\\ ", color_significant, branding, color_generic, " ///\n\n", color_significant, "Grabbing extension configurations...\n")
		grab_extensions(loader_directory .. loader_extension_path)
		MsgC(color_significant, "\nGrabbed extension configurations.\n\nConstructing load order...\n")
	else MsgC(color_generic, "\n\\\\\\ ", color_significant, branding, color_generic, " ///\n\n", color_significant, "Constructing load order...\n") end
	
	--create a table of load priorities
	construct_order(config, 1, "")
	MsgC(color_significant, "\nConstructed load order.\n\nLoading scripts by load order...\n")
	
	--then load them in that order relative to a path
	if command_reload then
		MsgC(color_generic, "\n!!! ", color_significant, "PRECONFIGURED LOADER NOTE", color_generic, " !!!\nAs the load was requested using command, the source file for the loader be used as a prefix for the following includes. You may experience issues with scripts loaded using this command that do not persist when the file is loaded by an include. If that happens, try making the file include itself instead of executing the load_scripts function in the reload command. You can do this by setting self_include_reload to true (attempts to automatically grab the file's path) or the full path of the loader.\n||| ", color_significant, "PRECONFIGURED LOADER NOTE", color_generic, " |||\n\n")
		load_by_order(loader_directory)
	else load_by_order("") end
	
	--we do this manually here so I don't keep adjusting its load order
	AddCSLuaFile("hooks.lua")
	include("hooks.lua")
	
	MsgC(color_significant, "\nLoaded scripts.\n\n", color_generic, "/// ", color_significant, "All scripts loaded.", color_generic, " \\\\\\\n\n")
end

--concommands
if isstring(reload_command) then
	concommand.Add(reload_command, function(ply)
		if CLIENT or not IsValid(ply) or ply:IsSuperAdmin() then
			if self_include_reload then
				--zero timers to prevent breaking of autoload?
				if isstring(self_include_reload) then timer.Simple(0, function() include(self_include_reload) end)
				else timer.Simple(0, function() include(loader_path) end) end
			else load_scripts(true) end
		end
	end, nil, "Reload all " .. branding .. " scripts.")
end

--post function setup
load_scripts(false)