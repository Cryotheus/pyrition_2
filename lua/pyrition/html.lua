--localized functions
local string_find = string.find
local string_sub = string.sub

--local tables
local void_types = {
	area = true,
	base = true,
	br = true,
	col = true,
	command = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	keygen = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true,
}

--local functions
local function find(march, body, pattern)
	local start, stop = string_find(body, pattern, march)
	
	if start then return start, stop, string_sub(body, start, stop) end
end

local function get_tag_parameters(raw_tag)
	local march, _, parameter = 1
	local parameters = {}
	local tag = string.gsub(raw_tag, "\\\"", string.char(7)) --substitute escaped quotes with a character that will never be used (the bell character)
	
	repeat
		_, march, parameter = find(march, tag, "%w-=\".-\"")
		
		if parameter then
			--get the text before the first = and after
			local equals = string.find(parameter, "=", 1, true)
			
			if equals then parameters[string_sub(parameter, 1, equals - 1)] = string_sub(parameter, equals + 2, -2)
			else table.insert(parameters, parameter) end
		else break end
	until not march
	
	return parameters
end

local function get_tag_type(tag)
	local _, _, class = find(1, tag, "[%a_!][%w_]*")
	
	return class
end

local function is_closing(tag) return string_find(tag, "</.->") ~= nil end
local function is_lonely(tag) return string_find(tag, "<.-/>") ~= nil or string_find(tag, "<!.->") ~= nil end
local function march_tag_close(march, body) return find(march, body, "</.->") end
local function march_tag_open(march, body) return find(march, body, "<.->") end
local function march_whitespace(march, body) return find(march, body, "%s*") end

local function xhtml_parse(body, callback, limit)
	local deserialized = {}
	local in_scope = deserialized
	local limit = limit or math.huge
	local tag_contents = {}
	local tags = {}
	local scope = {}
	local passes = 0
	local _, march = march_whitespace(1, body)
	
	repeat --build a list of tags
		local close_start, close_end, close_match = march_tag_close(march, body)
		local current_scope = scope[#scope]
		local decided_start, decided_end, decided_match
		local lonely_start, lonely_end, lonely_match-- = march_tag_lonely(march, body)
		local open_start, open_end, open_match = march_tag_open(march, body)
		passes = passes + 1
		
		if lonely_start and lonely_start < open_start then decided_start, decided_end, decided_match = lonely_start, lonely_end, lonely_match
		else
			if close_start and close_start < open_start then decided_start, decided_end, decided_match = close_start, close_end, close_match
			elseif open_start then decided_start, decided_end, decided_match = open_start, open_end, open_match end
		end
		
		if not decided_match then break end
		
		coroutine.yield()
		table.insert(tag_contents, string_sub(body, march + 1, decided_start - 1))
		table.insert(tags, decided_match)
		
		march = decided_end
	until passes > limit
	
	for index, tag in ipairs(tags) do
		local scope_depth = #scope
		local tag_content = tag_contents[index + 1] or ""
		local tag_type = get_tag_type(tag)
		
		local tag_table = {
			Content = tag_content,
			Parameters = get_tag_parameters(tag),
			Tag = tag,
			Type = tag_type,
		}
		
		if is_lonely(tag) or void_types[tag_type] then
			tag_table.Lonely = true
			
			table.insert(in_scope, tag_table)
		elseif is_closing(tag) then
			tag_table.Closer = true
			in_scope = scope[scope_depth - 1] or deserialized
			scope[scope_depth] = nil
		else
			table.insert(in_scope, tag_table)
			
			in_scope = tag_table
			scope[scope_depth + 1] = tag_table
		end
	end
	
	callback(deserialized)
end

--pyrition functions
function PYRITION:HTMLParseAsync(body, callback, budget)
	local budget = budget or 0.001
	local proxy = {IsValid = function(self) return coroutine.status(self.Thread) ~= "dead" end}
	proxy.Thread = coroutine.create(function() xhtml_parse(body, callback) end)
	
	hook.Add("Think", proxy, function()
		local finish = SysTime() + budget
		local thread = proxy.Thread
		
		while SysTime() < finish do
			local alive, message = coroutine.resume(thread)
			
			if not alive then return error("thread error: " .. message) end
		end
	end)
end