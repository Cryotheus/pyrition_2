--locals
local safety_flags = bit.bor(FCVAR_ARCHIVE, FCVAR_DONTRECORD, FCVAR_PROTECTED)

--localized functions
local escape
local query

--globals
PYRITION.SQLCoroutines = PYRITION.SQLCoroutines or {}
PYRITION.SQLSettings = PYRITION.SQLSettings or {}

--local functions
local function associate_convar(name, key, default, flags, type_key, callback)
	local type_key = type_key or "String"
	
	local convar = CreateConVar(name, tostring(default), flags, language.GetPhrase("pyrition.convars." .. name))
	local convar_get = convar["Get" .. type_key]
	local convar_set = convar["Set" .. type_key]
	local settings = PYRITION.SQLSettings
	
	settings[key] = convar_get(convar)
	
	if not callback then
		function callback(convar, _old, new)
			local new = convar_get(convar)
			settings[key] = new
			
			convar_set(convar, new)
		end
	end
	
	cvars.AddChangeCallback(name, function(_convar_name, ...) return callback(convar, ...) end, "PyritionSQL")
end

local function commit_queued(queued, completion_callback) --creates a coroutine for committing multiple queries in a queue
	local routine
	
	--we seperate the declaration and assignment so the coroutine is self-aware
	routine = coroutine.create(function()
		local active = true
		local entry = table.remove(queued, 1)
		
		repeat --process every queued query
			local instruction, callback, error_callback = unpack(entry)
			
			query(instruction, function(...)
				if callback then callback(...) end
				
				coroutine.resume(routine)
			end, function(...)
				if error_callback then error_callback(...) end
				
				coroutine.resume(routine)
			end)
			
			--wait until a callback is called
			coroutine.yield()
			
			--don't start the next iteration if we were discarded
			if not PYRITION.SQLCoroutines[routine] then
				active = false
				
				break
			end
			
			--prepare for next iteration
			entry = table.remove(queued, 1)
		until not entry
		
		if active then
			--final yield
			coroutine.yield()
			
			--discard
			PYRITION.SQLCoroutines[routine] = nil
		end
		
		--let the server hibernate again
		PYRITION:Hibernate(routine)
		
		--run our callback
		if completion_callback then completion_callback(active) end
	end)
	
	coroutine.resume(routine) --start the coroutine immediately
	PYRITION:HibernateWake(routine) --if the server is hibernating, the callback may not run
	
	--setup the global
	PYRITION.SQLCoroutines[routine] = queued
	
	return routine
end

--pyrition functions
function PYRITION:SQLBegin(queue) --Starts queuing all SQLQuery calls
	--returns the queue discarded, or false if no queue was started
	local queued = self.SQLQueued
	
	--if we already did SQLBegin, discard the queue
	--calling the method to allow hooking
	if queued then self:SQLDiscard() end
	
	self.SQLQueued = queue or {}
	
	return queued or false
end

function PYRITION:SQLCommit(completion_callback) --Stop queuing SQLQuery calls, and start them asynchronously
	--completion_callback is called when the coroutine made all queries or the queue was discarded
	--the parameter passed to completion_callback is true if we sent all queries, or false if the queue was dicarded
	local queued = self.SQLQueued
	
	if queued then return commit_queued(queued, completion_callback)
	else self:SQLDiscard() end
end

function PYRITION:SQLDiscard(routine) --Stop queuing SQLQuery calls and discard all calls queued since the last SQLBegin
	--give a coroutine to stop the coroutine given
	if routine then
		self.SQLCoroutines[routine] = nil
		
		return
	end
	
	self.SQLQueued = nil
end 

function PYRITION:SQLEscape(text) return escape(text) end --Convert a string into an sql safe string to prevent sql injection

function PYRITION:SQLQuery(instruction, callback, error_callback) --Perform or queue an sql query, optionally with callbacks
	if self.SQLQueued then
		table.insert(self.SQLQueued, {instruction, callback, error_callback})
		
		return
	end
	
	query(instruction, callback, error_callback)
end

--pyrition hooks
function PYRITION:PyritionSQLCreateTables(_database_name) --Setup your tables in here
	--database_name is nil if we are using SQLite, meaning you should prefix the table name with pyrition_
	--if database_name is a string, then use that as the database in which the table is a member of
	self:SQLCommit()
end

function PYRITION:PyritionSQLInitialize() --Called before PyritionSQLInitialized from InitPostEntity, attemtps to connect to the MySQL server
	if self.SQLInitializing then return false end
	
	local connect
	local settings = self.SQLSettings
	local enabled = settings.MySQLEnabled
	
	self.SQLInitializing = true
	
	--we need thinking!
	self:Hibernate("MySQL", false)
	timer.Remove("PyritionSQL")
	
	if enabled and file.Exists("bin/gmsv_mysqloo_*.dll", "LUA") then query, escape, connect = include("pyrition/sql/includes/mysqloo.lua")
	elseif enabled and file.Exists("bin/gmsv_tmysql4_*.dll", "LUA") then query, escape, connect = include("pyrition/sql/includes/tmysql4.lua")
	else
		query, escape = include("pyrition/sql/includes/sqlite.lua")
		
		if enabled then PYRITION:LanguageDisplay("mysql_fail", "pyrition.mysql.fail") end
	end
	
	if connect then
		connect(settings)
		
		return true
	end
	
	self:SQLInitialized()
	
	return true
end

function PYRITION:PyritionSQLInitialized(_database, database_name) --Called when MySQL connects, or immediately from PyritionSQLInitialized if MySQL is unavailable
	self.SQLDatabaseName = database_name or nil
	self.SQLInitializing = false
	
	self:Hibernate("MySQL")
	self:LanguageDisplay("sql_init", database_name and "pyrition.mysql.initialized" or "pyrition.sql.initialized")
	self:SQLBegin()
	self:SQLCreateTables(database_name or false)
end

--hooks
hook.Add("InitPostEntity", "PyritionSQL", function()
	PYRITION:LanguageDisplay("sql_init", "pyrition.sql.start")
	PYRITION:SQLInitialize()
end)

--post
associate_convar("pyrition_mysql_database", "MySQLDatabaseName", "pyrition", safety_flags)
associate_convar("pyrition_mysql_host", "MySQLHost", "localhost", safety_flags)
associate_convar("pyrition_mysql_password", "MySQLPassword", "password", safety_flags)
associate_convar("pyrition_mysql_port", "MySQLPort", 3306, safety_flags, "Int")
associate_convar("pyrition_mysql_username", "MySQLUsername", "pyrition_server", safety_flags)

associate_convar("pyrition_mysql_enabled", "MySQLEnabled", 0, safety_flags, "Bool", function(convar, old, new)
	local new = convar:GetBool()
	local settings = PYRITION.SQLSettings
	
	if new ~= settings.MySQLEnabled then
		if new then
			if PYRITION:SQLInitialize() then
				settings.MySQLEnabled = new
				
				convar:SetBool(new)
				
				return
			else PYRITION:LanguageDisplay("mysql_error", "pyrition.mysql.connect.fail.wait") end
		else
			PYRITION.SQLInitializing = false
			settings.MySQLEnabled = new
			
			convar:SetBool(new)
			PYRITION:SQLInitialize()
		end
	end
	
	convar:SetBool(old)
end)