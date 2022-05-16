--locals
local color_blue = Color(0, 0, 255)
local color_cyan = Color(0, 255, 255)
local color_green = Color(0, 255, 0)
local color_magenta = Color(255, 0, 255)
local color_red = Color(255, 0, 0)
local color_yellow = Color(255, 255, 0)

--globals
PYRITION = PYRITION or {}

--local functions, these are stolen from my Expression 2 scripts lol
local function power_lerp(fraction, power, alpha, bravo) return Lerp(fraction, alpha ^ power, bravo ^ power) ^ (1 / power) end
local function quadratic_lerp(fraction, alpha, bravo) return Lerp(fraction, alpha ^ 2, bravo ^ 2) ^ 0.5 end

local function mix(fraction, alpha, bravo)
	local alpha_r, alpha_g, alpha_b, alpha_a = alpha:Unpack()
	local bravo_r, bravo_g, bravo_b, bravo_a = bravo:Unpack()
	
	return Color(
		Lerp(fraction, alpha_r, bravo_r),
		Lerp(fraction, alpha_g, bravo_g),
		Lerp(fraction, alpha_b, bravo_b),
		Lerp(fraction, alpha_a, bravo_a)
	)
end

local function power_mix(fraction, power, alpha, bravo)
	local alpha_r, alpha_g, alpha_b, alpha_a = alpha:Unpack()
	local bravo_r, bravo_g, bravo_b, bravo_a = bravo:Unpack()
	
	return Color(
		power_lerp(fraction, power, alpha_r, bravo_r),
		power_lerp(fraction, power, alpha_g, bravo_g),
		power_lerp(fraction, power, alpha_b, bravo_b),
		power_lerp(fraction, power, alpha_a, bravo_a)
	)
end

local function quadratic_mix(fraction, alpha, bravo)
	local alpha_r, alpha_g, alpha_b, alpha_a = alpha:Unpack()
	local bravo_r, bravo_g, bravo_b, bravo_a = bravo:Unpack()
	
	return Color(
		quadratic_lerp(fraction, alpha_r, bravo_r),
		quadratic_lerp(fraction, alpha_g, bravo_g),
		quadratic_lerp(fraction, alpha_b, bravo_b),
		quadratic_lerp(fraction, alpha_a, bravo_a)
	)
end

local function somatic_gradient_map(fraction, map, formulae)
	local break_index
	local maximum
	local minimum = 0
	
	for index, threshold in ipairs(map) do
		if fraction < threshold then
			break_index = index
			maximum = threshold
			
			if index > 1 then minimum = map[index - 1] end
			
			break
		end
	end
	
	if not break_index then
		break_index = #formulae
		maximum = 1
		minimum = map[#map]
	end
	
	local range = maximum - minimum
	
	--we need to provide each formula with a fraction 0-1 instead of 0.2 - 0.6 or whatever
	--I would do math.Remap(fraction, minimum, maximum, 0, 1)
	--but that's bloated and I'm on a diet
	local difference = fraction - minimum
	local scaled_fraction = difference / range
	
	return formulae[break_index](scaled_fraction)
end

--globals
PYRITION._GradientMap = somatic_gradient_map