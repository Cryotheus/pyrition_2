--locals
--smallest possible positive float
local math_ceil = math.ceil
local math_floor = math.floor
local epsilon = 1.175494e-38

--globals
math.floatEpsilon = epsilon
PYRITION.Epsilon = epsilon

--global functions
function math.Remap(value, in_minimum, in_maximum, out_minimum, out_maximum)
	--rewrote to use less parenthesis
	return out_minimum + (value - in_minimum) / (in_maximum - in_minimum) * (out_maximum - out_minimum)
end

function math.Sign(value) return value > 0 and 1 or value < 0 and -1 or 0 end
function math.SignBiased(value) return value < 0 and -1 or 1 end

function math.Truncate(number, digits)
	--rewrote to use one less local
	local multiplier = 10 ^ (digits or 0)
	
	return (number < 0 and math_ceil or math_floor)(number * multiplier) / multiplier
end