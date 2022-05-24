--local variables
local color = Color(176, 176, 176)
local max_depth = 10

local operations_layers = {
	{
		["%^"] = function(left, right) return left ^ right end
	},
	
	{
		["%*"] = function(left, right) return left * right end,
		["/"] = function(left, right) return left / right end,
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
			local matcher = "[%d%.]+[%s" .. operator_match .. "]+[%d%.]+"
			
			while string.find(expression, matcher) do
				expression = string.gsub(expression, matcher, function(text)
					local alpha, bravo = string.match(text, "^[%d%.]+"), string.match(text, "[%d%.]+$")
					
					return tostring(operation(tonumber(alpha), tonumber(bravo)))
				end)
			end
		end
	end
	
	::sick_call::
	
	return ok and expression or ok
end

local function parse(text)
	--remove duplicate spaces and trims
	--because string.Trim wasn't trimming leading spaces
	text = string.gsub(text, "%s+", " ")
	local start = string.match(text, "^%s*()")
	
	return start <= #text and string.match(text, ".*%S", start) or false
end

--hooks
hook.Add("PyritionConsoleChatPosted", "PyritionConsoleChatCalculator", function(ply, message, team_chat, ply_dead, supressed)
	if string.StartWith(message, "=") then
		local parsed = parse(string.sub(message, 2))
		
		if not parsed then return end
		
		local calculation = calculate(parsed, 0)
		local text
		
		if calculation then text = "= " .. calculation
		elseif calculation == false then text = "= " .. language.GetPhrase("pyrition.chat.calculator.failed") end
		
		chat.AddText(color, text)
	end
end)