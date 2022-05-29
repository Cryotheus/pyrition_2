--enumerations
local TIME_DAY = 86400
local TIME_HOUR = 3600
local TIME_MINUTE = 60
local TIME_MONTH = 2592000 --30 days
local TIME_SECOND = 1
local TIME_WEEK = 604800
local TIME_YEAR = 31556926 --365.2422 days rounded up

--locals
local time_thresholds = PYRITION.TimeThresholds or {}

local time_unit_shorthand = PYRITION.TimeUnitShorthand or {
	[TIME_SECOND] = "s",
	[TIME_MINUTE] = "m",
	[TIME_HOUR] = "h",
	[TIME_DAY] = "d",
	[TIME_WEEK] = "w",
	[TIME_MONTH] = "m",
	[TIME_YEAR] = "y"
}

local time_units = PYRITION.TimeUnits or {
	[TIME_SECOND] = "second",
	[TIME_MINUTE] = "minute",
	[TIME_HOUR] = "hour",
	[TIME_DAY] = "day",
	[TIME_WEEK] = "week",
	[TIME_MONTH] = "month",
	[TIME_YEAR] = "year"
}

--local functions
local function grammar(quantity, unit)
	if quantity == 1 then return unit end
	
	return unit .. "s"
end

local function nice_time(seconds, recursions, use_grammar, thresholds, units, unit_seperator, block_seperator)
	--the built in nice time sucks
	local count = seconds
	local flooring = seconds
	local recursions = recursions or 0
	local thresholds = thresholds or time_thresholds
	local unit = "second"
	local units = units or time_units
	
	for index, threshold in ipairs(thresholds) do
		if seconds >= threshold then
			count = math.floor(seconds / threshold)
			flooring = count * threshold
			unit = units[threshold]
			
			if use_grammar then unit = grammar(count, unit) end
			
			break
		end
	end
	
	local text = count .. " " .. unit
	
	if recursions > 0 then
		local difference = seconds - flooring
		
		if difference > 0 then text = text .. " " .. nice_time(difference, recursions - 1) end
	end
	
	return text
end

local function parse_time(text, base)
	text = string.lower(text)
	
	if text == "" then return end
	
	for index, text in string.gmatch(text, "[%d]+[%D]*") do
		print(index, text)
	end
	
	return false
end

--globals
PYRITION.TimeUnits = time_units
PYRITION.TimeUnitShorthand = time_unit_shorthand
PYRITION.TimeThresholds = time_thresholds

PYRITION._TimeDay = TIME_DAY
PYRITION._TimeHour = TIME_HOUR
PYRITION._TimeMinute = TIME_MINUTE
PYRITION._TimeMonth = TIME_MONTH
PYRITION._TimeNicefy = nice_time
PYRITION._TimeParse = parse_time
PYRITION._TimeSecond = TIME_SECOND
PYRITION._TimeWeek = TIME_WEEK
PYRITION._TimeYear = TIME_YEAR

--post function set up
for threshold, unit in pairs(time_units) do table.insert(time_thresholds, threshold) end

table.sort(time_thresholds)

time_thresholds = table.Reverse(time_thresholds)