--nothing now--pseudo
--local variables
local max_depth = 10

local operations_layers = {
	{
		["%^"] = function(left, right) return left ^ right end
	},
	
	{
		["%*"] = function(left, right) return left * right end,
		["%/"] = function(left, right) return left / right end,
		["%%"] = function(left, right) return left % right end
	},
	
	{
		["%+"] = function(left, right) return left + right end,
		["%-"] = function(left, right) return left - right end
	}
}

--local functions
local function calculate(expression, depth)
	if depth > max_depth then return false end
	
	local ok = true
	
	if string.find(expression, "%b()") then
		expression = string.gsub(expression, "%b()", function(text)
			local calculation = calculate(string.sub(text, 2, #text - 1), depth + 1)
			
			if calculation then return calculation end
			
			ok = calculation
			
			return "?"
		end)
		
		if not ok then goto sick_call end
	end
	
	for layer, operations in ipairs(operations_layers) do
		for operator_match, operation in pairs(operations) do
			local matcher = "%d+[%s" .. operator_match .. "]+%d+"
			
			while string.find(expression, matcher) do
				expression = string.gsub(expression, matcher, function(text)
					--matches here
					return tostring(operation(tonumber(string.match(text, "^%d+")), tonumber(string.match(text, "%d+$"))))
				end)
			end
		end
	end
	
	::sick_call::
	
	return ok and expression or ok
end

local function parse(text)
	--remove duplicate spaces
	text = string.gsub(text, "%s+", " ")
	
	--trim the spaces at start and end
	--should be replaced with the built in trim c functions in glua
	local text_from = string.match(text, "^%s*()")
	
	return text_from > #text and "" or string.match(text, ".*%S", text_from)
end

--gamemode functions
local function chat(ply, message)
	print(ply:Nick() .. ": " .. message)
	
	if string.sub(message, 1, 1) == "=" then
		local calculation = calculate(parse(string.sub(message, 2)), 0)
		
		if calculation then print("= " .. calculation)
		elseif calculation == false then print("= max parenthesis depth reached") end
	end
end