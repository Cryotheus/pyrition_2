--locals
local player_storage_players = PYRITION.PlayerStoragePlayers or {}
local player_storages = PYRITION.PlayerStorages or {}
local read_only = false --RELEASE: convar this
local short_steam_id = PYRITION._SignificantDigitSteamID

--all the type names both MySQL and SQLite accept... probably...
local valid_type_names = {
	bigint = true,
	boolean = true,
	character = 1,
	clob = true,
	date = true,
	datetime = true,
	decimal = 2,
	double = true,
	float = true,
	int = true,
	int2 = true,
	int8 = true,
	integer = true,
	mediumint = true,
	nchar = 1,
	numeric = true,
	nvarchar = 1,
	real = true,
	smallint = true,
	text = true,
	tinyint = true,
	varchar = 1,
}

--local functions
local function escape_string(text) return PYRITION:SQLEscape(text) end
local function to_bool_string(state) return state and "true" or "false" end

local function to_numerical_string(number)
	number = tonumber(number)
	
	return number and tostring(number) or "0"
end

--post function setup
local type_name_conversion_functions = {
	bigint = tonumber,
	boolean = tobool,
	character = tostring,
	clob = tostring,
	date = tostring,
	datetime = tostring,
	decimal = tonumber,
	double = tonumber,
	float = tonumber,
	int = tonumber,
	int2 = tonumber,
	int8 = tonumber,
	integer = tonumber,
	mediumint = tonumber,
	nchar = tostring,
	numeric = tonumber,
	nvarchar = tostring,
	real = tonumber,
	smallint = tonumber,
	text = tostring,
	tinyint = tonumber,
	varchar = tostring,
}

local type_name_instruction_functions = {
	bigint = to_numerical_string,
	boolean = to_bool_string,
	character = escape_string,
	clob = escape_string,
	date = escape_string,
	datetime = escape_string,
	decimal = to_numerical_string,
	double = to_numerical_string,
	float = to_numerical_string,
	int = to_numerical_string,
	int2 = to_numerical_string,
	int8 = to_numerical_string,
	integer = to_numerical_string,
	mediumint = to_numerical_string,
	nchar = escape_string,
	numeric = to_numerical_string,
	nvarchar = escape_string,
	real = to_numerical_string,
	smallint = to_numerical_string,
	text = escape_string,
	tinyint = to_numerical_string,
	varchar = escape_string,
}

--globals
PYRITION.PlayerStorages = player_storages
PYRITION.PlayerStoragePlayers = player_storage_players

--pyrition functions
function PYRITION:PlayerStorageLoad(ply, key, tracker)
	local database_name = PYRITION.SQLDatabaseName
	local player_data = player_storage_players[ply]
	local player_datum = player_data[key]
	local storage_data = player_storages[key]
	local table_name = database_name and database_name .. "`.`" .. storage_data.TableName or "pyrition_" .. storage_data.TableName
	
	self:SQLQuery("select * from `" .. table_name .. "` where steam_id = '" .. player_data._ShortSteamID .. "';", function(result)
		if not IsValid(ply) then return end
		
		if not player_datum then
			player_datum = {}
			player_data[key] = player_datum
		end
		
		if result then
			local type_names = storage_data.TypeNames
			result = table.remove(result)
			result.steam_id = nil
			
			for index, field_key in ipairs(storage_data.Values) do player_datum[field_key] = type_name_conversion_functions[type_names[index]](result[field_key]) end
		end
		
		self:PlayerStorageLoaded(ply, key, player_datum, true, tracker)
	end, function()
		if not IsValid(ply) then return end
		
		if not player_datum then
			player_datum = {}
			player_data[key] = player_datum
		end
		
		self:PlayerStorageLoaded(ply, key, player_datum, false, tracker)
	end)
end

function PYRITION:PlayerStorageSave(ply, key)
	if read_only or ply:IsBot() then return end
	
	local database_name = PYRITION.SQLDatabaseName
	local player_data = player_storage_players[ply]
	local player_datum = player_data[key]
	
	hook.Call("PyritionPlayerStorageSave" .. key, self, ply, player_datum)
	
	local storage_data = player_storages[key]
	local table_name = database_name and database_name .. "`.`" .. storage_data.TableName or "pyrition_" .. storage_data.TableName
	local type_names = storage_data.TypeNames
	local values_placed = {"'" .. player_data._ShortSteamID .. "'"}
	
	for index, field_key in ipairs(storage_data.Values) do table.insert(values_placed, type_name_instruction_functions[type_names[index]](player_datum[field_key])) end
	
	self:SQLQuery("replace into `" .. table_name .. "` (" .. storage_data.ValuesString .. ") values(" .. table.concat(values_placed, ", ") .. ");")
end

--pyrition hooks
function PYRITION:PyritionPlayerStorageLoaded(_ply, key, player_data, _success, tracker)
	if tracker then
		tracker[key] = nil
		
		if table.IsEmpty(tracker) then PYRITION:PlayerStorageLoadFinished(ply, player_data) end
	end
end

function PYRITION:PyritionPlayerStorageLoadFinished(ply, player_data)
	local chronology = player_data.Time
	local identity = player_data.Identity
	local name = identity.name
	local previous_name = identity.PreviousName
	
	debug.Trace()
	
	if previous_name then
		local visit = chronology.visit or os.time()
		local visit_text = tostring(os.time() - visit)
		
		if previous_name == name then PYRITION:LanguageQueue(true, "pyrition.player.load", {executor = ply, visit = visit_text})
		else PYRITION:LanguageQueue(true, "pyrition.player.load.renamed", {executor = ply, name = name, visit = visit_text}) end
	else PYRITION:LanguageQueue(true, "pyrition.player.load.first", {executor = ply}) end
end

function PYRITION:PyritionPlayerStorageRegister(key, table_name, ...)
	local field_instructions = {}
	local fields = {...}
	local type_names_builder = {}
	local values_builder = {}
	
	assert(next(fields), "ID10T-15: No fields for player storage '" .. tostring(key) .. "'")
	
	for index, field_meta in ipairs(fields) do
		local field_key = field_meta.Key
		local type_name = string.lower(field_meta.TypeName)
		local valid = valid_type_names[type_name]
		
		assert(field_key and field_key ~= "steam_id", "ID10T-15: Invalid Key field. Key must not be nil or 'steam_id'")
		
		if valid then
			local type_name_instruction = type_name
			
			if isnumber(valid) then
				local parameters = field_meta.TypeParameters
				parameters = isnumber(parameters) and {parameters}
				
				assert(parameters and #parameters == valid, "ID10T-14: TypeParameters field has a mismatch in typename parameter quantity. Value required is " .. valid .. ", and value given is '" .. tostring(parameters and #parameters)  .. "'.")
				
				type_name_instruction = type_name_instruction .. "(" .. table.concat(parameters, ", ") .. ")"
			end
			
			if field_meta.Unsigned then type_name_instruction = type_name_instruction .. " unsigned" end
			if not field_meta.Optional then type_name_instruction = type_name_instruction .. " not null" end
			
			table.insert(type_names_builder, type_name)
			table.insert(field_instructions, "`" .. field_key .. "` " .. type_name_instruction)
			table.insert(values_builder, field_key)
		else ErrorNoHalt("ID10T-13: Invalid TypeName value '" .. tostring(type_name) .. "' for player storage registration.") end
	end
	
	player_storages[key] = {
		Fields = field_instructions,
		TableName = table_name,
		TypeNames = type_names_builder,
		Values = values_builder,
		ValuesString = "steam_id, " .. table.concat(values_builder, ", ")
	}
end

function PYRITION:PyritionPlayerStorageRegistration(database_name)
	for key, meta_data in pairs(player_storages) do
		local fields = table.Copy(meta_data.Fields)
		local table_name = database_name and database_name .. "`.`" .. meta_data.TableName or "pyrition_" .. meta_data.TableName
		
		table.insert(fields, 1, "`steam_id` varchar(12) not null")
		self:SQLQuery("create table if not exists `" .. table_name .. "` (" .. table.concat(fields, ", ") .. ", primary key (steam_id));",
			function(...) print("success", ...) end,
			function(...) print("failure", ...) end
		)
	end
end

--hooks
hook.Add("PlayerDisconnected", "PyritionPlayerStorage", function(ply)
	PYRITION:SQLBegin()
	for key, storage_data in pairs(player_storages) do PYRITION:PlayerStorageSave(ply, key) end
	PYRITION:SQLCommit()
	
	player_storage_players[ply] = nil
end)

hook.Add("PyritionSQLCreateTables", "PyritionPlayerStorage", function(database_name) PYRITION:PlayerStorageRegistration(database_name) end)

hook.Add("PyritionNetPlayerInitialized", "PyritionPlayerStorage", function(ply, _eumlated)
	player_storage_players[ply] = {_ShortSteamID = short_steam_id(ply)}
	local tracker = {}
	
	PYRITION:SQLBegin()
	
	for key, storage_data in pairs(player_storages) do
		tracker[key] = true
		
		PYRITION:PlayerStorageLoad(ply, key, true, tracker)
	end
	
	PYRITION:SQLCommit()
end)

--post
PYRITION:GlobalHookCreate("PlayerStorageRegister")