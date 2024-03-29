--enumerations
local TIME_DAY = 86400
local TIME_HOUR = 3600
local TIME_MINUTE = 60
local TIME_MONTH = 2592000 --30 days
local TIME_SECOND = 1
local TIME_WEEK = 604800
local TIME_YEAR = 31556926 --365.2422 days rounded up

local duplex_make_fooplex = duplex.MakeFooplex
local time_thresholds = PYRITION.TimeThresholds or {}

local time_unit_shorthand = PYRITION.TimeUnitShorthand or {
	[TIME_SECOND] = "s",
	[TIME_MINUTE] = "m",
	[TIME_HOUR] = "h",
	[TIME_DAY] = "d",
	[TIME_WEEK] = "w",
	[TIME_MONTH] = "mo",
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

local function grammar(quantity, unit)
	if quantity == 1 then return unit end

	return unit .. "s"
end

local function nice_time(seconds, recursions, use_grammar, thresholds, units, unit_separator, block_separator)
	--[[-ARGUMENTS:
		number "Time to format in seconds.",
		number "How many different units at the maximum should we use to represent the time.",
		boolean=true "Append the letter s to the end of the unit (unless the unit has a value of 1).",
		table=PYRITION.TimeThresholds "Use nil.",
		table=PYRITION.TimeUnits "Use nil.",
		string=" ",
		string=" "]]
	---RETURNS: string "Formatted text."
	---SEE: PYRITION._TimeShorthand
	---Formats seconds into an easier-to-read format.
	local block_separator = block_separator or " "
	local count = seconds
	local flooring = seconds
	local recursions = recursions or 0
	local thresholds = thresholds or time_thresholds
	local unit_separator = unit_separator or " "
	local units = units or time_units
	local use_grammar = use_grammar or use_grammar == nil

	local unit = units[1]

	for index, threshold in ipairs(thresholds) do
		if seconds >= threshold then
			count = math.floor(seconds / threshold)
			flooring = count * threshold
			unit = units[threshold]

			if use_grammar then unit = grammar(count, unit) end

			break
		end
	end

	local text = count .. unit_separator .. unit

	if recursions > 0 then
		local difference = seconds - flooring

		if difference > 0 then text = text .. block_separator .. nice_time(difference, recursions - 1, use_grammar, thresholds, units, unit_separator, block_separator) end
	end

	return text
end

local function parse_time(text, default_unit)
	---ARGUMENTS: string, number
	---RETURNS: number "Parsed time in seconds."
	---RETURNS: boolean "This will only ever be false and represents the conversion's failure."
	local default = time_units[default_unit] or time_unit_shorthand[default_unit] or TIME_SECOND
	local text = string.lower(string.gsub(text, "%-+", ""))

	if text == "" then return false end

	local time = false
	local report = {}

	for matched in string.gmatch(text, "[%d]+[%D]*") do
		local matched = string.gsub(matched, "%s+", "")
		local letters = string.match(matched, "%D+")
		local numerical = tonumber(string.match(matched, "[%d%.]+"))

		local multiplier = time_units[letters] or time_unit_shorthand[letters] or default

		if multiplier and numerical then
			if report[multiplier] then return false end

			if default == multiplier then
				if default == TIME_SECOND then default = nil
				else default = TIME_SECOND end
			end

			time = (time or 0) + numerical * multiplier
		else return false end
	end

	return time
end

local function shorthand_time(seconds, recursions)
	---ARGUMENTS: number, number=1 "How many time units should we use to represent the time?"
	---RETURNS: string
	---SEE: PYRITION._TimeNicefy
	---Formats $seconds into a more human-readable string.
	return nice_time(seconds, recursions, false, nil, time_unit_shorthand, "", "")
end

PYRITION.TimeDay = TIME_DAY
PYRITION.TimeHour = TIME_HOUR
PYRITION.TimeMinute = TIME_MINUTE
PYRITION.TimeMonth = TIME_MONTH
PYRITION.TimeSecond = TIME_SECOND
PYRITION.TimeThresholds = time_thresholds
PYRITION.TimeUnits = time_units
PYRITION.TimeUnitShorthand = time_unit_shorthand
PYRITION.TimeWeek = TIME_WEEK
PYRITION.TimeYear = TIME_YEAR

PYRITION._TimeNicefy = nice_time
PYRITION._TimeParse = parse_time
PYRITION._TimeShorthand = shorthand_time

table.Empty(time_thresholds)

for threshold, unit in pairs(time_units) do
	if isnumber(threshold) then
		table.insert(time_thresholds, threshold)
	end
end

table.sort(time_thresholds)

time_thresholds = table.Reverse(time_thresholds)

duplex_make_fooplex(time_unit_shorthand, true)
duplex_make_fooplex(time_units, true)