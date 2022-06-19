--local functions
local function globalify(local_name) --turns some_class_name into SomeClassName
	local global_name = ""
	
	for index, word in ipairs(string.Split(local_name, "_")) do global_name = global_name .. string.upper(string.Left(word, 1)) .. string.lower(string.sub(word, 2)) end
	
	return global_name
end

--globals
PYRITION._GlobalifyName = globalify