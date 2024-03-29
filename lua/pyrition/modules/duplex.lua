--pragma once
if duplex then return end

local assert = assert
local ipairs = ipairs
local isnumber = isnumber
local pairs = pairs
local table_Copy = table.Copy
local table_Count = table.Count
local table_insert = table.insert
local table_maxn = table.maxn
local table_remove = table.remove
local table_sort = table.sort
local type = type

--no need for package.seall, we're not using many globals
module("duplex")

function Collapse(duplex)
	---ARGUMENTS: table
	---RETURNS: table
	---Shifts values down to make a sequential duplex, modifying the original table.
	---Basically: "turns a fooplex into a duplex"
	local maximum = table_maxn(duplex)
	local shift

	for index = 1, maximum do
		local value = duplex[index]

		if value == nil then
			index = index + 1

			if shift then shift = shift + 1
			else shift = 1 end
		elseif shift then
			local new_index = index - shift
			duplex[new_index] = value
			duplex[value] = new_index
		end

		index = index + 1
	end

	--remove all shifted values
	for index = maximum - shift + 1, maximum do duplex[index] = nil end

	return duplex
end

function Destroy(duplex)
	---ARGUMENTS: table
	---RETURNS: table
	---Turns the duplex into a list, modifying the original table.
	for index, value in ipairs(duplex) do duplex[value] = nil end

	return duplex
end

function Extract(duplex)
	---ARGUMENTS: table
	---RETURNS: table
	--Creates a list from the duplex, without touching the original.
	local copy = {}

	for index, value in ipairs(duplex) do copy[index] = value end

	return copy
end

function InheritEntry(target, source, index)
	---ARGUMENTS: table, table, any
	---RETURNS: any
	if isnumber(index) then return Set(target, index, source[index]) end

	return Set(target, source[index], index)
end

function Insert(duplex, value, set_value)
	---ARGUMENTS: table, any
	---ARGUMENTS: table, number, any
	---RETURNS: number
	if isnumber(value) then return Set(duplex, value, set_value) end

	local index = duplex[value]

	if index == nil then
		index = table_insert(duplex, value)
		duplex[value] = index
	end

	return index
end

function IsFooplex(duplex)
	---ARGUMENTS: table
	---RETURNS: boolean
	---Returns true if the duplex is not sequential, false otherwise.
	local count = table_Count(duplex)

	--quick check by comparing counts
	if count ~= #duplex * 2 then return true end

	--slower check by
	for index = 1, count * 0.5 do if duplex[index] == nil then return true end end

	return false
end

function Make(duplex, modify)
	---ARGUMENTS: table, boolean
	---RETURNS: table
	---Creates a duplex from a sequential table, or turns the original into one instead of creating a new table entirely.
	local duplex = modify and duplex or table_Copy(duplex)

	for index, value in ipairs(duplex) do duplex[value] = index end

	return duplex
end

function MakeFooplex(duplex, modify)
	---ARGUMENTS: table, boolean
	---RETURNS: table
	---Creates a non-sequential duplex (fooplex) from a sequential table, or turns the original into one instead of creating a new table entirely.
	local duplex = modify and duplex or table_Copy(duplex)

	for index, value in pairs(duplex) do if isnumber(index) then duplex[value] = index end end

	return duplex
end

function Remove(duplex, index)
	---ARGUMENTS: table, number
	---RETURNS: any
	---Removes an entry from the duplex, and returns the value. All following entries are shifted down.
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
	---ARGUMENTS: table, number, any
	---RETURNS: number
	---Sets a value at a specific index in the duplex, and returns the index.

	assert(isnumber(position), "Attempt to set a non-numerical " .. type(position) .. " index in duplex.")
	assert(value ~= nil, "Attempt to set a nil value in duplex. Use duplex.Unset instead.")

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
	---ARGUMENTS: table, function=nil
	---RETURNS: table, table
	---Sorts the duplex, and returns the sorted table and a list of the values.
	local values = Extract(duplex)

	table_sort(values, sorter)

	for index, value in ipairs(values) do
		duplex[index] = value
		duplex[value] = index
	end

	return duplex, values
end

function Unset(duplex, index)
	---ARGUMENTS: table, any
	---RETURNS: any
	---Removes an entry from the duplex, and returns the index. This does not shift down the following entries.
	local value = duplex[index]
	duplex[index] = nil

	if value then duplex[value] = nil end

	return isnumber(index) and index or value
end