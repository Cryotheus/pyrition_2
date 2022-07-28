--local functions
local function query(instruction, callback, error_callback)
	local result = sql.Query(instruction)
	
	if result then
		if callback then callback(result) end
		
		return result
	end
	
	if error_callback then error_callback(sql.LastError()) end
end

--post
return query, sql.SQLStr