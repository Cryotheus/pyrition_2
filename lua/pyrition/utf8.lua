--locals
local utf8_len = utf8.len

--local functions
local function utf8_safe(text, limit) return utf8_len(text, 1, limit) == utf8_len(text, 1, limit - 1) end

--globals
PYRITION._UTF8Safe = utf8_safe