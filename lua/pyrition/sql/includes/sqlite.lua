--local functions
local function query(instruction, callback, error_callback)
	local result = sql.Query(instruction)
	
	if result then
		if callback then
			if table.IsEmpty(result) then callback(nil)
			else callback(result) end
		end
		
		return
	end
	
	if error_callback then error_callback(sql.LastError()) end
end

--post
return query, sql.SQLStr