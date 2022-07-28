require("mysqloo")

--locals
local database
local reconnecting

--local functions
local function connect(settings, callback, reconnection, retry)
	local retry = retry or 0
	database = mysqloo.connect(settings.MySQLHost, settings.MySQLUsername, settings.MySQLPassword, settings.MySQLDatabaseName, settings.MySQLPort)
	
	function database:onConnected()
		if retry > 1 then PYRITION:LanguageDisplay("mysql_connect", "pyrition.mysql.connect", {attempts = retry}) end
		if callback then callback(true) end
		if reconnection then return end
		
		PYRITION:SQLInitialized(database)
	end
	
	function database:onConnectionFailed(error_message)
		if retry == 0 then PYRITION:LanguageDisplay("mysql_error", "pyrition.mysql.connect.fail", {message = tostring(error_message)}) end
		
		timer.Create("PyritionSQL", 5, 1, function() connect(settings, callback, reconnection, retry + 1) end)
	end
	
	database:connect()
end

local function escape(unsafe) return "\"" .. database:escape(tostring(unsafe)) .. "\"" end

local function query(instruction, callback, error_callback)
	local query_object = database:query(instruction)
	local data = {}
	
	--when an entry is received
	function query_object:onData(datum) table.insert(data, datum) end
	
	function query_object:onError(error_code)
		if database:status() == mysqloo.DATABASE_NOT_CONNECTED then
			if reconnecting then
				table.insert(reconnecting, {instruction, callback, error_callback})
				
				return
			end
			
			reconnecting = {}
			
			connect(PYRITION.SQLSettings, function(success)
				if success then
					query(instruction, callback, error_callback)
					
					for index, arguments in ipairs(reconnecting) do query(unpack(arguments)) end
					
					reconnecting = nil
				elseif error_callback then error_callback(error_code) end
			end, true)
			
			return
		end
		
		if error_callback then error_callback(error_code) end
	end
	
	if callback then
		function query_object:onSuccess(result)
			MsgC(Color(128, 64, 255), "result table\n")
			PrintTable(result or {"not a table"})
			
			MsgC(Color(128, 64, 255), "\ndata table\n")
			PrintTable(data or {"not a table"})
			
			if table.IsEmpty(data) then callback(nil) end
			
			callback(data)
		end
	end
	
	query_object:start()
end

return query, escape, connect