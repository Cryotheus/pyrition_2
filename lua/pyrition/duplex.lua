--pyrition functions
function PYRITION:DuplexInsert(duplex, value)
	if duplex[value] == nil then
		local index = table.insert(duplex, value)
		duplex[value] = index
		
		return index
	end
	
	return false
end

function PYRITION:DuplexRemove(duplex, index)
	index = index or #duplex
	local value = duplex[index]
	
	if value then
		table.remove(duplex, index)
		
		duplex[value] = nil
		
		--update the following values
		for march = index, #duplex do
			local indexed_value = duplex[march]
			
			duplex[indexed_value] = march
		end
		
		return value
	end
	
	return false
end

function PYRITION:DuplexUnset(duplex, value)
	local index = duplex[value]
	
	if isnumber(index) then
		table.remove(duplex, index)
		
		duplex[value] = nil
		
		--update the following values
		for march = index, #duplex do
			local indexed_value = duplex[march]
			
			duplex[indexed_value] = march
		end
		
		return index
	end
	
	return false
end