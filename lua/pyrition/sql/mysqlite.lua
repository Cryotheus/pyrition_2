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
local connected_to_mysql = false
local mysql_connect
local queued_queries
local safety_flags = bit.bor(FCVAR_ARCHIVE, FCVAR_DONTRECORD, FCVAR_PROTECTED)

--localized into scope/environment
local CreateConVar = CreateConVar
local cvars = cvars
local escape_function
local error = error
local language = language
local mysql_escape
local mysqloo = mysqloo
local mysql_query
local pairs = pairs
local PYRITION = PYRITION
local query_function
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
local function finish_connection()
	connected_to_mysql = true
	
	for key, value in pairs(cached_queries) do
		if value[3] then queryValue(value[1], value[2])
		else query(value[1], value[2]) end
	end
	
	PYRITION:Hibernate("MySQL", false)
	table.Empty(cached_queries)
	PYRITION:SQLInitialized()
end

local function get_any_member(tbl) return select(2, next(tbl)) end

local function mysql_connect(retry)
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
	
	PYRITION:Hibernate("MySQL")
	DatabaseObject:connect()
end

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
		
		PYRITION:Hibernate("MySQL")
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

--module functions
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
	query_function = sql_query
	
	PYRITION:Hibernate("MySQL", false)
	PYRITION:SQLInitialized()
	timer.Remove("pyrmysql_connect")
end
