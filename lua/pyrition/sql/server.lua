--locals
local safety_flags = bit.bor(FCVAR_ARCHIVE, FCVAR_DONTRECORD, FCVAR_PROTECTED)
local settings = PYRITION.SQLSettings or {}

--localized functions
local escape
local query

--local functions
local function associate_convar(name, key, default, flags, type_key, callback)
	local type_key = type_key or "String"
	
	local convar = CreateConVar(name, tostring(default), flags, language.GetPhrase("pyrition.convars." .. name))
	local convar_get = convar["Get" .. type_key]
	local convar_set = convar["Set" .. type_key]
	
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

--pyrition functions
function PYRITION:SQLBegin()
	queue = {}
	self.SQLQueued = queue
end

function PYRITION:SQLCommit(local_queue, index)
	local local_queue
	
	if local_queue then
		index = index or 1
		values = local_queue[index]
		
		query(unpack(values))
		
	else self:SQLDiscard() end
	
	
end

function PYRITION:SQLDiscard()
	queue = nil
	self.SQLQueued = nil
end

function PYRITION:SQLEscape(text) return escape(text) end

function PYRITION:SQLQuery(instruction, callback, error_callback)
	if queue then
		table.insert(queue, {instruction, callback, error_callback})
		
		return
	end
	
	query(instruction, callback, error_callback)
end

--pyrition hooks
function PYRITION:PyritionSQLInitialize()
	if self.SQLInitializing then return false end
	
	local connect
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

function PYRITION:PyritionSQLCreateTables() self:SQLCommit() end

function PYRITION:PyritionSQLInitialized(_database, database_name)
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