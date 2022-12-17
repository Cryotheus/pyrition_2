--locals
local direction_planes = {}
local directions = {}
local directions_bilateral = {}
local directions_negated = {}
local huge_negative_vector = Vector(-math.huge, -math.huge, -math.huge)
local huge_vector = Vector(math.huge, math.huge, math.huge)
local vector_meta = FindMetaTable("Vector")

--localized functions
local math_abs = math.abs
local math_ceil = math.ceil
local math_Clamp = math.Clamp
local math_floor = math.floor
local math_min = math.min
local math_Truncate = math.Truncate
local Vector = Vector

--local functions
local function remaining_axes(axis)
	if axis < 0 then return -axis % 3 + 1, (1 - axis) % 3 + 1 end
	
	return axis % 3 + 1, (axis + 1) % 3 + 1
end

--globals
PYRITION._RemainingAxes = remaining_axes

--vector meta functions, a preceding ! in comments indicates that the <self> vector is modified
function vector_meta:__le(right) return self.x <= right.x and self.y <= right.y and self.z <= right.z end
function vector_meta:__lt(right) return self.x < right.x and self.y < right.y and self.z < right.z end

function vector_meta:Absolute() --!makes components positive
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	self.z = math.abs(self.z)
	
	return self
end

function vector_meta:AbsoluteDot(right) return math_abs(self:Dot(right)) end

function vector_meta:Bounds(target) --returns a minimums and maximums between vectors
	local maximum_x, maximum_y, maximum_z
	local minimum_x, minimum_y, minimum_z
	local target_x, target_y, target_z = target:Unpack()
	local self_x, self_y, self_z = self:Unpack()
	
	if target_x > self_x then maximum_x, minimum_x = target_x, self_x
	else maximum_x, minimum_x = self_x, target_x end
	
	if target_y > self_y then maximum_y, minimum_y = target_y, self_y
	else maximum_y, minimum_y = self_y, target_y end
	
	if target_z > self_z then maximum_z, minimum_z = target_z, self_z
	else maximum_z, minimum_z = self_z, target_z end
	
	return Vector(minimum_x, minimum_y, minimum_z), Vector(maximum_x, maximum_y, maximum_z)
end

function vector_meta:Ceil() --!rounds a vector up
	self.x = math_ceil(self.x)
	self.y = math_ceil(self.y)
	self.z = math_ceil(self.z)
	
	return self
end

function vector_meta:Clamp(minimum, maximum) --!clamp a vector to a minimum and maximum value, vectors or numbers can be used
	if isnumber(minimum) then
		self.x = math_Clamp(self.x, minimum, maximum)
		self.y = math_Clamp(self.y, minimum, maximum)
		self.z = math_Clamp(self.z, minimum, maximum)
		
		return self
	end
	
	self.x = math_Clamp(self.x, minimum.x, maximum.x)
	self.y = math_Clamp(self.y, minimum.y, maximum.y)
	self.z = math_Clamp(self.z, minimum.z, maximum.z)
	
	return self
end

function vector_meta:Clone() return Vector(self.x, self.y, self.z) end

function vector_meta:ClosestAxis() --returns the closest axis a vector is aligned to
	local normalized = self:GetNormalized():Absolute()
	local record_axis = 0
	local record_distance = math.huge
	
	for axis = 1, 3 do
		local distance = normalized:Distance(directions[axis])
		
		if distance < record_distance then
			record_axis = axis
			record_distance = distance
		end
	end
	
	return self[record_axis] < 0 and -record_axis or record_axis
end

function vector_meta:CubeIntersect(delta_vector, minimums, maximums) --find a bounds intersection given an offset
	--given the position, the delta to our target, and bounds: where does this interect our universal bounds?
	local destination = self + delta_vector
	local record_scalar = 1
	
	--order of subtraction is important, since we want positive deltas in our algorithm
	local maximums_boundary_delta = maximums - self
	local maximums_destination_delta = destination - maximums
	local minimums_boundary_delta = self - minimums
	local minimums_destination_delta = minimums - destination
	
	--find the smallest scalar we can get, from the properly signed axes
	for axis = 1, 3 do
		if delta_vector[axis] > 0 then --positive axes
			local delta = maximums_destination_delta[axis]
			
			if delta > 0 then record_scalar = math_min(maximums_boundary_delta[axis] / delta, record_scalar) end
		else --negative axes
			local delta = minimums_destination_delta[axis]
			
			if delta > 0 then record_scalar = math_min(minimums_boundary_delta[axis] / delta, record_scalar) end
		end
	end
	
	return self + delta_vector * record_scalar
end

function vector_meta:CubeIntersectTarget(destination, minimums, maximums) --find a bounds intersection given a target
	--give then position, the delta to our target, and bounds:
	--where does this interect our universal bounds?
	local delta_vector = destination - self
	local record_scalar = 1
	
	--order of subtraction is important, since we want positive deltas in our algorithm
	local maximums_boundary_delta = maximums - self
	local maximums_destination_delta = destination - maximums
	local minimums_boundary_delta = self - minimums
	local minimums_destination_delta = minimums - destination
	
	--find the smallest scalar we can get, from the properly signed axes
	for axis = 1, 3 do
		if delta_vector[axis] > 0 then --positive axes
			local delta = maximums_destination_delta[axis]
			
			if delta > 0 then record_scalar = math_min(maximums_boundary_delta[axis] / delta, record_scalar) end
		else --negative axes
			local delta = minimums_destination_delta[axis]
			
			if delta > 0 then record_scalar = math_min(minimums_boundary_delta[axis] / delta, record_scalar) end
		end
	end
	
	return self + delta_vector * record_scalar
end

function vector_meta:Dwells(minimums, maximums) return self >= minimums and self <= maximums end --returns if the point is contained by the two vectors (includes surfaces)

function vector_meta:Floor() --!rounds a vector down
	self.x = math_floor(self.x)
	self.y = math_floor(self.y)
	self.z = math_floor(self.z)
	
	return self
end

function vector_meta:GetAxis(intolerance) --returns the closest axis a UNIT VECTOR is aligned to, or false if it was not greater than intolerance (default of 0.99)
	local intolerance = intolerance or 0.99
	
	for axis = 1, 3 do
		local component = self[axis]
		
		if math.abs(component) > intolerance then return component > 0 and axis or -axis end
	end
	
	return false
end

function vector_meta:GetZeroed(zero) return Vector(self.x == 0 and zero, self.y == 0 and zero, self.z == 0 and zero) end --returns a vector with all components of zero set to the sepcified amount
function vector_meta:Inside(minimums, maximums) return self > minimums and self < maximums end --returns if the point is contained by the two vectors (excludes surfaces)

function vector_meta:MultiBounds(...) --same as Bounds but can take as many vectors as you want
	local maximums = huge_negative_vector:Clone()
	local minimums = huge_vector:Clone()
	
	for index, vector in ipairs{self, ...} do
		--debugoverlay.Cross(vector, 10, 5, color_white, true)
		
		for axis = 1, 3 do
			local component = vector[axis]
			
			if component > maximums[axis] then maximums[axis] = component end
			if component < minimums[axis] then minimums[axis] = component end
		end
	end
	
	return minimums, maximums
end

function vector_meta:SetLength(magnitude) return self:Mul(magnitude / self:Length()) end --!sets the vector's length
function vector_meta:SetZeroes(zero) for axis = 1, 3 do if self[axis] == 0 then self[axis] = zero end end end --!sets all components of zero to the sepcified amount

function vector_meta:TriangleNormal(second, third) --given two additional points, returns the normal of the triangle
	local normal = (second - self):Cross(third - self)
	
	normal:Normalize()
	
	return normal
end

function vector_meta:Truncate(digits) --!round componenets towards zero
	digits = digits or 0
	
	self.x = math_Truncate(self.x, digits)
	self.y = math_Truncate(self.y, digits)
	self.z = math_Truncate(self.z, digits)
	
	return self
end

function vector_meta:WithMagnitude(magnitude) return self * magnitude / self:Length() end

--post
for axis = 1, 3 do
	local direction = Vector()
	local plane = Vector(1, 1, 1)
	direction[axis] = 1
	plane[axis] = 0
	
	direction_planes[axis] = plane
	direction_planes[-axis] = plane
	directions[axis] = direction
	directions[-axis] = -direction
	directions_bilateral[axis * 2 - 1] = direction
	directions_bilateral[axis * 2] = -direction
	directions_negated[axis] = -direction
	directions_negated[-axis] = direction
end