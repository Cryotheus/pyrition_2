--localized functions
local pyrmysql = pyrmysql

--pyrition hooks
function PYRITION:PyritionSQLCreateTables() pyrmysql.commit() end

function PYRITION:PyritionSQLInitialized()
	local database_name = pyrmysql.isMySQL() and pyrmysql.MySQLDatabaseName or false
	self.SQLDatabaseName = database_name
	
	self:LanguageDisplay("sql_init", database_name and "pyrition.mysql.initialized" or "pyrition.sql.initialized")
	
	pyrmysql.begin()
	self:SQLCreateTables(database_name)
end

--hooks
hook.Add("InitPostEntity", "PyritionSQL", function()
	PYRITION:LanguageDisplay("sql_init", "pyrition.sql.start")
	pyrmysql.initialize()
end)