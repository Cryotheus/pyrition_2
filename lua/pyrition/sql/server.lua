--locals
--"localhost", "developer", "developer", database_name, 3306
--pyrition hooks
function PYRITION:PyritionSQLInitialized()
	self:LanguageDisplay("sql_init", pyrmysql.isMySQL() and "pyrition.mysql.initialized" or "pyrition.sql.initialized")
end

--hooks
hook.Add("InitPostEntity", "PyritionSQL", function()
	PYRITION:LanguageDisplay("sql_init", "pyrition.sql.start")
	pyrmysql.initialize()
end)