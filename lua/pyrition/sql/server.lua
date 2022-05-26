--locals

--localized functions
local pyrmysql = pyrmysql

--pyrition hooks
function PYRITION:PyritionSQLCreateTables() pyrmysql.commit() end

function PYRITION:PyritionSQLInitialized()
	local is_mysql = pyrmysql.isMySQL()
	
	self:LanguageDisplay("sql_init", is_mysql and "pyrition.mysql.initialized" or "pyrition.sql.initialized")
	
	pyrmysql.begin()
	self:SQLCreateTables(is_mysql, pyrmysql.MySQLDatabaseName)
end

--hooks
hook.Add("InitPostEntity", "PyritionSQL", function()
	PYRITION:LanguageDisplay("sql_init", "pyrition.sql.start")
	pyrmysql.initialize()
end)