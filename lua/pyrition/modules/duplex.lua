--pragma once
if duplex then return end

--locals
local assert = assert
local ipairs = ipairs
local isnumber = isnumber
local pairs = pairs
local table_Copy = table.Copy
local table_Count = table.Count
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local type = type

--post function setup
module("duplex")

--module functions
function Destroy(duplex) --turn a duplex into a list
	for index, value in ipairs(duplex) do duplex[value] = nil end
	
	return duplex
end

function Extract(duplex) --get a list from a duplex
	local copy = {}
	
	for index, value in ipairs(duplex) do copy[index] = value end
	
	return copy
end

function InheritEntry(target, source, index)
	if isnumber(index) then return Set(target, index, source[index]) end
	
	return Set(target, source[index], index)
end

function Insert(duplex, value, set_value)
	if isnumber(value) then return Set(duplex, value, set_value) end
	
	if duplex[value] == nil then
		local index = table_insert(duplex, value)
		duplex[value] = index
		
		return index
	end
	
	return false
end

function IsFooplex(duplex) --check duplex for "holes"
	local count = table_Count(duplex)
	
	--quick check by comparing counts
	if count ~= #duplex * 2 then return true end
	
	--slower check by
	for index = 1, count * 0.5 do if duplex[index] == nil then return true end end
	
	return false
end

function Make(duplex, modify)
	local duplex = modify and duplex or table_Copy(duplex)
	
	for index, value in ipairs(duplex) do duplex[value] = index end
	
	return duplex
end

function MakeFooplex(duplex, modify)
	local duplex = modify and duplex or table_Copy(duplex)
	
	for index, value in pairs(duplex) do if isnumber(index) then duplex[value] = index end end
	
	return duplex
end

function Remove(duplex, index)
	local value
	
	if index then
		if isnumber(index) then value = duplex[index]
		else value, index = index, duplex[index] end
	else index = #duplex end
	
	if index and value then
		table_remove(duplex, index)
		
		duplex[value] = nil
		
		--update the following values
		for march = index, #duplex do
			local indexed_value = duplex[march]
			
			duplex[indexed_value] = march
		end
		
		return value
	end
	
	return nil
end

function Set(duplex, position, value)
	assert(isnumber(position), "ID10T-8: Attempt to set a non-numerical " .. type(position) .. " index in duplex.")
	assert(value ~= nil, "ID10T-9: Attempt to set a nil value in duplex. Use duplex.Unset instead.")
	
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

function Sort(duplex, sorter)
	local values = Extract(duplex)
	
	table_sort(values, sorter)
	
	for index, value in ipairs(values) do
		duplex[index] = value
		duplex[value] = index
	end
	
	return duplex, values
end

function Unset(duplex, index)
	local value = duplex[index]
	duplex[index] = nil
	
	if value then duplex[value] = nil end
	
	return isnumber(index) and index or value 
end