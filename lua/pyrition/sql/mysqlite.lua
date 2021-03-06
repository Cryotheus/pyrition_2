--inspired from our lord and savio FPtje Christ
--https://github.com/FPtje/MySQLite/blob/a03be015d33c8ac7d304220e72f048e352a91c13/mysqlite.lua

--TL;DR
--mysqlite but only mysqloo support >:D

--no autoreload allowed!
if pyrmysql then return end

--module is required
if file.Exists("bin/gmsv_mysqloo_*.dll", "LUA") then require("mysqloo")
elseif file.Exists("bin/gmsv_tmysql4_*.dll", "LUA") then require("tmysql4")
else hook.Add("InitPostEntity", function() PYRITION:LanguageDisplay("mysql_fail", "pyrition.mysql.fail") end) end

--locals
local cached_queries = {}
local changing_hibernate = false
local connected_to_mysql = false
local mysql_connect
local need_thinking = false
local queued_queries
local restore_hibernate
local safety_flags = bit.bor(FCVAR_ARCHIVE, FCVAR_DONTRECORD, FCVAR_PROTECTED)
local sv_hibernate_think = GetConVar("sv_hibernate_think")

local controlling_hibernate = not sv_hibernate_think:GetBool()

--localized into scope/environment
local CreateConVar = CreateConVar
local cvars = cvars
local escape_function
local error = error
local hibernate
local language = language
local mysql_escape
local mysqloo = mysqloo
local mysql_query
local pairs = pairs
local PYRITION = PYRITION
local query_function
local RunConsoleCommand = RunConsoleCommand
local sql = sql
local table = table
local timer = timer
local tmysql = tmysql
local tmysql_escape
local tmysql_query
local tostring = tostring

--module!
module("pyrmysql")

--module fields
DatabaseObject = nil

--local functions
local function associate_convar(name, key, default, flags, type_key, callback)
	local type_key = type_key or "String"
	
	local convar = CreateConVar(name, tostring(default), flags, language.GetPhrase("pyrition.convars." .. name))
	local convar_get = convar["Get" .. type_key]
	local convar_set = convar["Set" .. type_key]
	local module_table = _M
	
	module_table[key] = convar_get(convar)
	
	if not callback then
		function callback(convar, old, new)
			local new = convar_get(convar)
			module_table[key] = new
			
			convar_set(convar, new)
		end
	end
	
	cvars.AddChangeCallback(name, function(convar_name, ...) return callback(convar, ...) end, "pyrmysql")
end

local function change_hibernate(value)
	changing_hibernate = true
	
	RunConsoleCommand("sv_hibernate_think", value and "1" or "0")
end

local function finish_connection()
	connected_to_mysql = true
	need_thinking = false
	
	for key, value in pairs(cached_queries) do
		if value[3] then queryValue(value[1], value[2])
		else query(value[1], value[2]) end
	end
	
	hibernate()
	table.Empty(cached_queries)
	PYRITION:SQLInitialized()
end

local function get_any_member(tbl) return select(2, next(tbl)) end

function hibernate()
	if controlling_hibernate then change_hibernate(false)
	else change_hibernate(restore_hibernate) end
end

local function mysql_connect(retry)
	need_thinking = true
	DatabaseObject = mysqloo.connect(MySQLHost, MySQLUsername, MySQLPassword, MySQLDatabaseName, MySQLPort)
	local retry = retry or 0
	
	function DatabaseObject:onConnected()
		if not MySQLEnabled then return end
		if retry > 1 then PYRITION:LanguageDisplay("mysql_connect", "pyrition.mysql.connect", {attempts = retry}) end
		
		escape_function = mysql_escape
		query_function = mysql_query
		
		finish_connection()
	end
	
	function DatabaseObject:onConnectionFailed(error_message)
		if retry == 0 then PYRITION:LanguageDisplay("mysql_error", "pyrition.mysql.connect.fail", {message = tostring(error_message)}) end
		
		timer.Create("pyrmysql_connect", 5, 1, function() mysql_connect(retry + 1) end)
	end
	
	change_hibernate(true)
	DatabaseObject:connect()
end

function mysql_escape(unsafe) return "\"" .. DatabaseObject:escape(tostring(unsafe)) .. "\"" end

function mysql_query(instruction, callback, error_callback, query_value)
	local query_object = DatabaseObject:query(instruction)
	local data
	local reconnect_try = 0
	
	function query_object:onData(datum)
		data = data or {}
		data[#data + 1] = datum
	end
	
	function query_object:onError(error_code)
		if DatabaseObject:status() == mysqloo.DATABASE_NOT_CONNECTED then
			table.insert(cached_queries, {instruction, callback, query_value})
			
			reconnect_try = reconnect_try + 1
			mysql_connect(MySQLHost, MySQLUsername, MySQLPassword, MySQLDatabaseName, MySQLPort)
			
			return
		end
		
		local suppress = error_callback and error_callback(error_code, instruction)
		
		if suppress == false then error(error_code .. " (" .. instruction .. ")") end
	end

	function query_object:onSuccess()
		local result = query_value and data and data[1] and get_any_member(data[1]) or not query_value and data or nil
		
		if callback then callback(result, query_object:lastInsert()) end
	end
	
	query_object:start()
end

local function sql_query(instruction, callback, error_callback, query_value)
	sql.m_strError = "" --reset last error
	
	local last_error = sql.LastError()
	local result = query_value and sql.QueryValue(instruction) or sql.Query(instruction)
	
	if sql.LastError() and sql.LastError() ~= last_error then
		local new_error = sql.LastError()
		local suppress = error_callback and error_callback(new_error, instruction)
		
		if suppress == false then error(new_error .. " (" .. instruction .. ")", 2) end
		
		return
	end
	
	if callback then callback(result) end
	
	return result
end

local function tmysql_connect(retry)
	local database, error_message = tmysql.Connect(MySQLHost, MySQLUsername, MySQLPassword, MySQLDatabaseName, MySQLPort)
	local retry = retry or 0
	
	if error_message then
		if retry == 0 then PYRITION:LanguageDisplay("mysql_error", "pyrition.mysql.connect.fail", {message = tostring(error_message)}) end
		
		need_thinking = true
		
		change_hibernate(true)
		timer.Create("pyrmysql_connect", 5, 1, function() tmysql_connect(retry + 1) end)
		
		return
	end
	
	if not MySQLEnabled then return end
	if retry > 1 then PYRITION:LanguageDisplay("mysql_connect", "pyrition.mysql.connect", {attempts = retry}) end
	
	DatabaseObject = database
	escape_function = tmysql_escape
	query_function = tmysql_query
	
	finish_connection()
end

function tmysql_escape(unsafe) return "\"" .. DatabaseObject:Escape(tostring(unsafe)) .. "\"" end

function tmysql_query(instruction, callback, error_callback, query_value)
	local call = function(results)
		local result = results[1]
		
		if not result.startus then
			local error_code = result.error
			local suppress = error_callback and error_callback(error_code, instruction)
			
			if suppress == false then error(error_code .. " (" .. instruction .. ")") end
			
			return
		end
		
		local data = result.data
		
		if not data or #result == 0 then data = nil end
		if query_value and callback then return callback(data and data[1] and get_any_member(data[1]) or nil) end
		if callback then callback(data, result.lastid) end
	end
	
	DatabaseObject:Query(instruction, call)
end

--post function setup
associate_convar("pyrition_mysql_database", "MySQLDatabaseName", "pyrition", safety_flags)
associate_convar("pyrition_mysql_host", "MySQLHost", "localhost", safety_flags)
associate_convar("pyrition_mysql_password", "MySQLPassword", "password", safety_flags)
associate_convar("pyrition_mysql_port", "MySQLPort", "3306", safety_flags, "Int")
associate_convar("pyrition_mysql_username", "MySQLUsername", "pyrition_server", safety_flags)

associate_convar("pyrition_mysql_enabled", "MySQLEnabled", "0", safety_flags, "Bool", function(convar, old, new)
	local new = convar:GetBool()
	
	if new ~= MySQLEnabled then
		MySQLEnabled = new
		
		initialize()
	end
	
	convar:SetBool(new and "1" or "0")
end)

cvars.AddChangeCallback("sv_hibernate_think", function(convar_name, old, new)
	if changing_hibernate then
		changing_hibernate = false
		
		return
	end
	
	local fetch = sv_hibernate_think:GetBool()
	
	controlling_hibernate = false
	restore_hibernate = fetch
	
	if need_thinking then change_hibernate(true) end
end, "pyrmysql")

--module functions
function begin()
	if connected_to_mysql then
		if queued_queries then error("Transaction ongoing!") end
		
		queued_queries = {}
	else sql.Begin() end
end

function commit(on_finished)
	if not connected_to_mysql then
		sql.Commit()
		
		if on_finished then on_finished() end
		
		return
	end
	
	if not queued_queries then error("No queued queries! Call begin() first!") end
	
	if table.IsEmpty(queued_queries) then
		queued_queries = nil
		
		if on_finished then on_finished() end
		
		return
	end
	
	--copy the table so other scripts can create their own queue
	local call
	local queue = table.Copy(queued_queries)
	local queue_position = 0
	
	queued_queries = nil
	
	--recursion!
	function call(...)
		queue_position = queue_position + 1
		local queue_callback = queue[queue_position].callback
		
		if queue_callback then queue_callback(...) end
		
		if queue_position + 1 > #queue then
			if on_finished then on_finished() end
			
			return
		end
		
		local next_query = queue[queue_position + 1]
		
		query(next_query.query, call, next_query.onError)
	end
	
	query(queue[1].query, call, queue[1].onError)
end

function initialize()
	if connected_to_mysql then
		if mysqloo then DatabaseObject:disconnect()
		else DatabaseObject:Disconnect() end
		
		DatabaseObject = nil
		connected_to_mysql = false
	end
	
	if MySQLEnabled then
		if mysqloo then return mysql_connect()
		elseif tmysql then return tmysql_connect() end
	end
	
	escape_function = sql.SQLStr
	need_thinking = false
	query_function = sql_query
	
	change_hibernate(false)
	PYRITION:SQLInitialized()
	timer.Remove("pyrmysql_connect")
end

function isMySQL() return connected_to_mysql end

function query(instruction, callback, error_callback) return query_function(instruction, callback, error_callback, false) end
function queryValue(instruction, callback, error_callback) return query_function(instruction, callback, error_callback, true) end

function queueQuery(instruction, callback, error_callback)
	if connected_to_mysql then
		table.insert(queued_queries, {
			callback = callback,
			onError = error_callback,
			query = instruction
		})
		
		return
	end
	
	--SQLite is instantaneous, simply running the query is equal to queueing it
	query(instruction, callback, error_callback)
end

function SQLStr(unsafe) return escape_function(unsafe) end

function tableExists(dable, callback, error_callback)
	if not connected_to_mysql then
		local exists = sql.TableExists(dable)
		
		callback(exists)
		
		return exists
	end
	
	queryValue("SHOW TABLES LIKE " .. SQLStr(dable), function(value) callback(value ~= nil) end, error_callback)
end