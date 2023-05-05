--locals
local ticked

--local functions
local function query(instruction, callback, error_callback)
	local result = sql.Query(instruction)

	if ticked then table.insert(ticked, {result, callback, error_callback, sql.LastError()})
	else
		--same as `timer.Simple(0 function() ...the code... end)`
		--but properly wakes up and hibernates the server
		PYRITION:HibernateSafeZeroTimer(function()
			ticked = {{result, callback, error_callback, sql.LastError()}}

			for index, variables in ipairs(ticked) do
				local result = variables[1]
				local callback = variables[2]
				local error_callback = variables[3]
				local sql_error = variables[4]

				if result then
					if callback then
						if table.IsEmpty(result) then callback(nil)
						else callback(result) end
					end

					return
				end

				if error_callback then error_callback(sql_error) end
			end
		end)
	end
end

--post
return query, sql.SQLStr