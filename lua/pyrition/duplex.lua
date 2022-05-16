--locals
local duplex_set

--local functions
local function duplex_destroy(duplex)
	--turn a duplex into a list
	for index, value in ipairs(duplex) do duplex[value] = nil end
	
	return duplex
end

local function duplex_extract(duplex)
	--get a list from a duplex
	local copy = {}
	
	for index, value in ipairs(duplex) do copy[index] = value end
	
	return copy
end

local function duplex_insert(duplex, value, set_value)
	if isnumber(value) then return duplex_set(duplex, value, set_value) end
	
	if duplex[value] == nil then
		local index = table.insert(duplex, value)
		duplex[value] = index
		
		return index
	end
	
	return false
end

local function duplex_is_fooplex(duplex)
	local count = table.Count(duplex)
	
	--quick check by comparing counts
	if count ~= #duplex * 2 then return true end
	
	--slower check by
	for index = 1, count * 0.5 do if duplex[index] == nil then return true end end
	
	return false
end

local function duplex_remove(duplex, index)
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

function duplex_set(duplex, position, value)
	assert(isnumber(position), "ID10T-8: Attempt to set a non-numerical " .. type(position) .. " index in duplex.")
	assert(value ~= nil, "ID10T-9: Attempt to set a nil value in duplex. Use PYRITION._DuplexUnset instead.")
	
	local old_index = duplex[value]
	
	if old_index then
		duplex[old_index] = nil
		duplex[value] = nil
	end
	
	if duplex[position] then duplex[position] = nil end
	
	duplex[value] = position
	duplex[position] = value
	
	return position
end

local function duplex_sort(duplex, sorter)
	local list = duplex_extract(duplex)
	
	table.sort(list, sorter)
	
	for index, value in ipairs(list) do
		duplex[index] = value
		duplex[value] = index
	end
	
	return duplex, list
end

local function duplex_unset(duplex, value)
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

--globals
PYRITION._DuplexDestroy = duplex_destroy
PYRITION._DuplexExtract = duplex_extract
PYRITION._DuplexInsert = duplex_insert
PYRITION._DuplexIsFooplex = duplex_is_fooplex
PYRITION._DuplexRemove = duplex_remove
PYRITION._DuplexSet = duplex_set
PYRITION._DuplexSort = duplex_sort
PYRITION._DuplexUnset = duplex_unset

--[[ copy paste this in your locals header

local duplex_destroy = PYRITION._DuplexDestroy
local duplex_extract = PYRITION._DuplexExtract
local duplex_insert = PYRITION._DuplexInsert
local duplex_is_fooplex = PYRITION._DuplexIsFooplex
local duplex_remove = PYRITION._DuplexRemove
local duplex_set = PYRITION._DuplexSet
local duplex_sort = PYRITION._DuplexSort
local duplex_unset = PYRITION._DuplexUnset

]]