--locals
local player_storage_players = PYRITION.PlayerStoragePlayers or {}
local player_storages = PYRITION.PlayerStorages or {}

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

--[[
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
} --]]

--localized functions
local pyrmysql = pyrmysql

--local functions
local function short_steam_id(steam_id)
	if IsEntity(steam_id) then steam_id = steam_id:SteamID() end
	
	return steam_id[9] .. string.sub(steam_id, 11)
end

--globals
PYRITION.PlayerStorages = player_storages
PYRITION.PlayerStoragePlayers = player_storage_players

--pyrition functions
function PYRITION:PlayerStorageLoad(ply, table_name, database_name)
	--local player_data = player_storage_players[ply]
	--local storage_data = player_storages[key]
	
	local result = pyrmysql.query(
		database_name and "select * from `" .. database_name .. "`.`" .. table_name .. "` where steam_id = '172956761';"
		or "select * from `" .. table_name .. "` where steam_id = '172956761';"
	)
	
	PrintTable(result or {"nil"})
	
	--for index, field_key in ipairs(storage_data.Values) do player_data[field_key] = type_name_conversion_functions[type_name](result[field_key]) end
end

function PYRITION:PlayerStorageSave(ply, table_name, database_name)
	local player_data = player_storage_players[ply]
	local storage_data = player_storages[key]
	local values_placed = {short_steam_id(ply)}
	
	for index, field_key in ipairs(storage_data.Values) do table.insert(values_placed, tostring(player_data[field_key])) end
	
	pyrmysql.query(
		database_name and "replace into `" .. database_name .. "`.`" .. table_name .. "` (" .. storage_data.ValuesString .. ") values(" .. values_placed .. ");"
		or "replace into `" .. table_name .. "` (" .. storage_data.ValuesString .. ") values(" .. values_placed .. ");"
	)
end

--pyrition hooks
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
		else ErrorNoHalt("ID10T-13: Invalid TypeName value '" .. tostring(type_name) .. "' for player storage registration.")
	end
	
	player_storages[key] = {
		Fields = field_instructions,
		TableName = table_name,
		TypeNames = type_names_builder,
		Values = values_builder,
		ValuesString = "steam_id, " .. table.concat(values_builder, ", ")
	}
end

function PYRITION:PyritionPlayerStorageRegistration(is_mysql, database_name)
	for key, meta_data in pairs(player_storages) do
		local fields = table.Copy(meta_data.Fields)
		
		if is_my_sql then
			table.insert(fields, 1, "`steam_id` varchar(12) not null")
			pyrmysql.queueQuery("create table if not exists `" .. database_name .. "`.`" .. meta_data.TableName .. "` ("  .. table.concat(fields, ", ") .. ", primary key (steam_id));")
		else
			table.insert(fields, 1, "`steam_id` varchar(12) not null primary key") end
			pyrmysql.queueQuery("create table if not exists `" .. meta_data.TableName .. "` (" .. table.concat(fields, ", ") .. ")")
		end
	end
end

--hooks
hook.Add("PyritionSQLCreateTables", "PyritionPlayerStorage", function(is_mysql, database_name) PYRITION:PlayerStorageRegistration(is_mysql, database_name) end)

--post
PYRITION:GlobalHookCreate("PlayerStorageRegister")