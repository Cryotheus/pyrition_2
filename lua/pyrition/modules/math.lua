--locals
--local double_epsilon = 4.94065645841246544176568792868E-324
--local float_epsilon = 1.175494e-38
local math_ceil = math.ceil
local math_max = math.max
local math_min = math.min
local math_floor = math.floor

--local functions
local function bezier_nomial(point_index, point_count)
	local point_local = "p" .. point_index
	local inverse_power = point_count - point_index
	local fraction_power = point_index - 1

	local nomial = string.format(
		"%s * f ^ %i * i ^ %i",
		point_local,
		fraction_power,
		inverse_power
	)

	--remove "* word ^ 0 "
	nomial = string.gsub(nomial, "%* %l+ %^ 0 ", "")

	--replace "base ^ 1" with "base"
	nomial = string.gsub(nomial, "%l+ %^ 1", function(text) return string.gsub(text, " .+", "") end)

	--replace "base ^ 2" with "base * base"
	nomial = string.gsub(nomial, "%l+ %^ 2", function(text)
		local base = string.gsub(text, " .+", "")

		return base .. " * " .. base
	end)

	return nomial
end

local function bezier_point_regression_formula(point_count)
	local nomials = {}
	local pascal_row = math.PascalRow(point_count)

	--calculate each nomial
	for index = 1, point_count do
		local nomial = bezier_nomial(index, point_count)

		if index == 1 or index == point_count then
			--the first and last columns of any row in pascal's triangle are 1
			--so don't add that redundant "1 * " to the nomial
			nomials[index] = nomial
		else nomials[index] = pascal_row[index] .. " * " .. nomial end
	end

	--add all the nomials together
	--there's always an extra " * i ^ 0" at the end
	return string.sub(table.concat(nomials, " + "), 1, -9)
end

--global functions
function math.Approach(current, target, increment)
	---Same as it is in the [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/math.Approach)
	--because the source does this, we must keep it in case other addons rely on it
	if increment < 0 then increment = -increment end

	if current < target then return math_min(current + increment, target)
	elseif current > target then return math_max(current - increment, target) end

	return target
end

function math.ApproachPA(current, target, increment)
	---Proof-abiding version of `math.Approach`, this will let the value "run away" if given a negative increment.
	---This behavior will not happen if `current` is equal to `target`.
	if current == target then return target
	elseif increment < 0 then
		if current < target then return current + increment
		else return current - increment end
	else
		if current < target then return math_min(current + increment, target)
		else return math_max(current - increment, target) end
	end
end

function math.CompileBezier(point_count) --return a bezier function for the given point count
	--3 is quadratic, 4 is cubic, 5 is quartic, and so on
	--you only need to call this once, ever
	--if you're learning, don't learn from this
	--it's not very readable, but the function it compiles is the fastest solution I know
	--and no, I'm not going to use binary modules (violates workshop rules)

	--to access the function, use math.Bezier#
	--where # is what the number you gave math.CompileBezier
	local key = "Bezier" .. point_count
	local existing_function = math[key]

	if existing_function then return existing_function end

	local formula = bezier_point_regression_formula(point_count)
	local parameters = {}

	--generate parameters table used in function definition, and our regression function
	for index = 1, point_count do parameters[index] = "p" .. index end

	--we use a global to pass the function to CompileString
	--and no, RunString doesn't work here because it can't return values
	local e = "--auto-generated by Pyrition\nreturn function(f," .. table.concat(parameters, ",") .. ")\n\tlocal i = 1 - f\n\treturn " .. formula .. "\nend", "Pyrition math.Bezier" .. point_count
	
	print(e)

	local bezier = CompileString(e)()
	math[key] = bezier

	return bezier
end

function math.IntersectionByPoints(alpha_start_x, alpha_start_y, alpha_end_x, alpha_end_y, bravo_start_x, bravo_start_y, bravo_end_x, bravo_end_y)
	local x_difference_x, x_difference_y = alpha_start_x - alpha_end_x, bravo_start_x - bravo_end_x
	local y_difference_x, y_difference_y = alpha_start_y - alpha_end_y, bravo_start_y - bravo_end_y
	local dividend = x_difference_x * y_difference_y - x_difference_y * y_difference_x

	if dividend == 0 then return false end

	local line_x = alpha_start_x * alpha_end_y - alpha_start_y * alpha_end_x
	local line_y = bravo_start_x * bravo_end_y - bravo_start_y * bravo_end_x

	return
		(line_x * x_difference_y - line_y * x_difference_x) / dividend,
		(line_x * y_difference_y - line_y * y_difference_x) / dividend
end

function math.PascalRow(line)
	local line = line - 1
	local row = {1}

	for index = 0, line - 1 do table.insert(row, row[index + 1] * (line - index) / (index + 1)) end

	return row
end

function math.Remap(value, in_minimum, in_maximum, out_minimum, out_maximum)
	---Same as it is in the [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/math.Remap)
	--rewrote to use less parenthesis
	return out_minimum + (value - in_minimum) / (in_maximum - in_minimum) * (out_maximum - out_minimum)
end

function math.Sign(value) return value > 0 and 1 or value < 0 and -1 or 0 end
function math.SignBiased(value) return value < 0 and -1 or 1 end

function math.Truncate(number, digits)
	---Same as it is in the [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/math.Truncate)
	--rewrote to use one less local
	local multiplier = 10 ^ (digits or 0)

	return (number < 0 and math_ceil or math_floor)(number * multiplier) / multiplier
end