require("tmysql4")

--locals
local database

--local functions
local function connect(settings, callback, reconnection, retry)
	local database_name = settings.MySQLDatabaseName
	local error_message
	local retry = retry or 0
	database, error_message = tmysql.initialize(settings.MySQLHost, settings.MySQLUsername, settings.MySQLPassword, database_name, settings.MySQLPort)
	
	if error_message then
		if retry == 0 then PYRITION:LanguageDisplay("mysql_error", "pyrition.mysql.connect.fail", {message = tostring(error_message)}) end
		
		timer.Create("PyritionSQL", 5, 1, function() connect(settings, callback, reconnection, retry + 1) end)
		
		return
	end
	
	if retry > 1 then PYRITION:LanguageDisplay("mysql_connect", "pyrition.mysql.connect", {attempts = retry}) end
	if reconnection then return end
	if callback then callback(true) end
	
	PYRITION:SQLInitialized(database, database_name)
end

local function escape(unsafe) return "\"" .. DatabaseObject:Escape(tostring(unsafe)) .. "\"" end

local function query(instruction, callback, error_callback)
	database:Query(instruction, function(results)
		local first_result = results[1]
		
		if not first_result.status then
			if error_callback then error_callback(first_result.error) end
			
			return
		end
		
		local aggregator = {}
		
		for index, query_object in ipairs(results) do table.insert(aggregator, query_object.data) end
		
		if table.IsEmpty(aggregator) then callback(nil)
		else callback(aggregator) end
	end)
end

--post
return query, escape, connect