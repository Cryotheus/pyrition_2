--locals
local drop_trace = {}
local escape_vector = Vector(0, 0, 0.1) --we have a problem with the spot left solid being start solid
local initial_radius = 1
local max_ascension = 256
local max_ascension_vector = Vector(0, 0, max_ascension)
local max_attempts = 20
local max_distance = 256
local max_drop = -256
local max_drop_attempts = 5
local max_drop_vector = Vector(0, 0, max_drop - max_ascension)
local pi = math.pi
local pi_half = pi * 0.5
local pi_quarter = pi * 0.25
local tau = pi * 2

--local tables
local drop_trace_data = { --hash-map-uh!
	endpos = vector_origin,
	filter = NULL,
	mask = MASK_PLAYERSOLID,
	maxs = vector_origin,
	mins = vector_origin,
	output = drop_trace,
	start = vector_origin
}

--local functions
local function calculate_drop(attempts, start_position, level_position, end_position, bounding_mins, bounding_maxs)
	--try to get a position that is not in a wall, nor in the air
	drop_trace_data.endpos = end_position
	drop_trace_data.maxs = bounding_maxs
	drop_trace_data.mins = bounding_mins
	drop_trace_data.start = start_position
	
	util.TraceHull(drop_trace_data)
	
	if drop_trace.StartSolid then
		local difference = end_position - start_position
		local new_start = difference * drop_trace.FractionLeftSolid + start_position - escape_vector
		
		if attempts < max_drop_attempts then return calculate_drop(attempts + 1, new_start, level_position, end_position, bounding_mins, bounding_maxs)
		else return level_position, false end
	else
		if drop_trace.Hit then return drop_trace.HitPos, true
		else return level_position, false end
	end
end

local function calculate_radian_max(radius, radian_increment, first_apparition_radius) return tau - (first_apparition_radius / radius + radian_increment) end

local function destination_suitable(apparition, position, bounding_mins, bounding_maxs, force)
	--check if we can put a player there without them suffering
	local success
	position, success = calculate_drop(0, position + max_ascension_vector, position, position + max_drop_vector, bounding_mins, bounding_maxs)
	
	if success or force then return position end
	
	return false
end

local function find_suitable_landings(target, apparitions, force)
	local destination_count = 0
	local destinations = {}
	local first_apparition_radius
	local last_radius
	local previous_apparition_radius
	local radian
	local radius
	local target_minimum, target_maximum = target:GetCollisionBounds()
	local target_position = target:GetPos()
	local target_radius = (target_minimum - target_maximum):Length2D()
	
	drop_trace_data.filter = apparitions
	
	for apparition_index, apparition in ipairs(apparitions) do
		local apparition_force = force or apparition:GetMoveType() == MOVETYPE_NOCLIP
		local apparition_minimum, apparition_maximum = apparition:GetCollisionBounds()
		local landing
		
		local apparition_diameter = (apparition_maximum - apparition_minimum):Length2D() --this isn't 19whateverthefucks, sqaures roots don't take a billion cycles, they take 1
		local apparition_radius = apparition_diameter * 0.5
		local apparition_radii = apparition_radius + (previous_apparition_radius or apparition_radius)
		
		--we need this to determine when we go into the next ring
		if not first_apparition_radius then first_apparition_radius = apparition_radius end
		
		--compensation differing hitboxes
		if radius then if last_radius + apparition_diameter > radius then radius = last_radius + apparition_diameter end
		else
			radius = (apparition_radius + target_radius) * initial_radius
			last_radius = radius - apparition_diameter
		end
		
		--calculate how much we increase the angle per itteration, and then also when to go into the next ring
		local radian_increment = apparition_radii / radius
		local radian_max = calculate_radian_max(radius, radian_increment, first_apparition_radius)
		
		if not radian then radian = -radian_increment end
		
		--start building a ring
		for attempt = 1, max_attempts do
			radian = radian + radian_increment
			
			landing = destination_suitable(apparition, Vector(math.cos(radian) * radius, math.sin(radian) * radius, 0) + target_position, apparition_minimum, apparition_maximum, force)
			
			if radian >= radian_max then
				first_apparition_radius = apparition_radius
				last_radius = radius
				radius = radius + apparition_diameter
				
				radian_increment = apparition_radii / radius
				radian_max = calculate_radian_max(radius, radian_increment, first_apparition_radius)
				
				radian = -radian_increment
			end
			
			--if we found a landing, then go on to the next player
			if landing then break end
		end
		
		if landing then
			destination_count = destination_count + 1
			destinations[apparition_index] = landing
		else break end
		
		previous_apparition_radius = apparition_radius
	end
	
	return destinations, destination_count
end

--pyrition functions
function PYRITION:PyritionPlayerLanding(target, apparitions) return find_suitable_landings(target, apparitions) end