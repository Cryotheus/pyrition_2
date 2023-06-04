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

--pyrition functions
function PYRITION:VectorCompileBezier(point_count)
	---ARGUMENTS: number
	---Compiles a bezier method into the Vector metatable.
	---You only need to call this once, per point count.
	---The created method is named Bezier# where # is the point count specified.
	--[[-```
		--only call these once, anywhere before you need to use them.
		PYRITION:VectorCompileBezier(3)
		PYRITION:VectorCompileBezier(4)

		--now you can use the newly created methods as much as you want
		Msg(Vector(1, 2, 3):Bezier3(0.75, Vector(4, 5, 6), Vector(7, 8, 9)))
		Msg(Vector(1, 2, 3):Bezier4(0.75, Vector(4, 5, 6), Vector(7, 8, 9), Vector(10, 11, 12)))
	```]]

	--if you're learning, don't learn from this
	--it's not very readable, but the function it compiles is the fastest solution I know
	--and no, I'm not going to use binary modules (violates workshop rules)
	local key = "Bezier" .. point_count

	if vector_meta[key] then return end

	local parameters = {}
	local x_parameters, y_parameters, z_parameters = {"b(f"}, {"b(f"}, {"b(f"}

	--generate parameters table
	for index = 1, point_count do
		local next_index = index + 1
		local parameter = "p" .. index

		--the first is already supplied before the fraction (named f)
		--this is because p1 is the equivalent of self in a typical method
		parameters[index] = "p" .. index + 1
		x_parameters[next_index] = parameter .. "[1]"
		y_parameters[next_index] = parameter .. "[2]"
		z_parameters[next_index] = parameter .. "[3]"
	end

	--we use a global to pass the function to CompileString
	--and no, RunString doesn't work here because it can't return values
	PyritionBezierFunction = math.CompileBezier(point_count)
	parameters[point_count] = nil --we don't need the last parameter

	--broken down in hopes to make it more readable (doesn't really help)
	vector_meta[key] = CompileString(
		"--auto-generated by Pyrition\nlocal b,v=PyritionBezierFunction,Vector\nreturn function(p1,f,"
		.. table.concat(parameters, ",") .. ")\n\treturn v("
		.. table.concat(x_parameters, ",") .. "), "
		.. table.concat(y_parameters, ",") .. "), "
		.. table.concat(z_parameters, ",") .. "))\nend", identifier
	)()

	--clean this up so people don't use it, because you know they for some reason would if I didn't
	PyritionBezierFunction = nil
end

--vector meta functions, a preceding ! in comments indicates that the <self> vector is modified
function vector_meta:__le(right) return self.x <= right.x and self.y <= right.y and self.z <= right.z end
function vector_meta:__lt(right) return self.x < right.x and self.y < right.y and self.z < right.z end

function vector_meta:Absolute()
	---RETURNS: self
	---Makes all of the components of the vector positive.
	---This modifies the vector.
	self.x = math_abs(self.x)
	self.y = math_abs(self.y)
	self.z = math_abs(self.z)

	return self
end

function vector_meta:AbsoluteDot(right)
	---ARGUMENTS: Vector
	---RETURNS: number
	---Returns the absolute value of the dot product of two vectors.
	return math_abs(self:Dot(right))
end

function vector_meta:Approach(target, distance)
	---ARGUMENTS: Vector, number
	---RETURNS: Vector
	---Returns a vector that is moved $distance units closer to the $target vector.
	if self:Distance(target) <= distance then return target end

	local direction = target - self

	direction:Normalize()

	return direction * distance + self
end

function vector_meta:Bounds(target)
	---ARGUMENTS: Vector
	---RETURNS: Vector "Minimums.", Vector "Maximums."
	---Returns a minimum position and maximum position between two vectors.
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

function vector_meta:Ceil()
	---RETURNS: self
	---Round the vector up to the nearest integer.
	---This modifies the vector.
	self.x = math_ceil(self.x)
	self.y = math_ceil(self.y)
	self.z = math_ceil(self.z)

	return self
end

function vector_meta:Clamp(minimum, maximum)
	---ARGUMENTS: Vector, Vector
	---ARGUMENTS: number, number
	---RETURNS: self
	---Clamp the vector's components to a minimum and maximum value.
	---If provided numbers, the vector's components will be clamped to those numbers.
	---If provided vectors, the vector's components will be clamped to the corresponding component of the vector.
	---This modifies the vector.
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

function vector_meta:Clone()
	---Returns a copy of the vector.
	return Vector(self.x, self.y, self.z)
end

function vector_meta:ClosestAxis()
	---Returns the closest axis a vector is aligned to.
	---A number 1-3 is returned representing the component, and negative values represent negative axes.
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

function vector_meta:CubeIntersect(delta_vector, minimums, maximums)
	---Find a bounds intersection from the vector given an offset and the bounds.
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

function vector_meta:CubeIntersectTarget(destination, minimums, maximums)
	---Find a bounds intersection from the vector given a target and bounds.
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

function vector_meta:Dwells(minimums, maximums)
	---Returns true if the point is contained by the two vectors (specifying bounds) (includes surfaces)
	return self >= minimums and self <= maximums
end

function vector_meta:Floor()
	--RETURNS: self
	---Round the vector down to the nearest integer.
	---This modifies the vector.
	self.x = math_floor(self.x)
	self.y = math_floor(self.y)
	self.z = math_floor(self.z)

	return self
end

function vector_meta:GetAxis(intolerance)
	---ARGUMENTS: number=0.99
	---RETURNS: boolean
	---Returns the closest axis a UNIT VECTOR is aligned to, or false if it was not greater than intolerance (default of 0.99)
	local intolerance = intolerance or 0.99

	for axis = 1, 3 do
		local component = self[axis]

		if math.abs(component) > intolerance then return component > 0 and axis or -axis end
	end

	return false
end

function vector_meta:GetZeroed(zero)
	---ARGUMENTS: number
	---RETURNS: Vector
	---Returns a vector with all components of zero set to the sepcified amount.
	return Vector(self.x == 0 and zero, self.y == 0 and zero, self.z == 0 and zero)
end

function vector_meta:Inside(minimums, maximums)
	---RETURNS: self
	---Returns true if the point is contained by the two vectors (specifying bounds) (excludes surfaces)
	return self > minimums and self < maximums
end

function vector_meta:MultiBounds(...)
	--Same as Bounds but can take as many vectors as you want.
	---ARGUMENTS: Vector
	---RETURNS: Vector, Vector
	local maximums = huge_negative_vector:Clone()
	local minimums = huge_vector:Clone()

	for index, vector in ipairs{self, ...} do
		for axis = 1, 3 do
			local component = vector[axis]

			if component > maximums[axis] then maximums[axis] = component end
			if component < minimums[axis] then minimums[axis] = component end
		end
	end

	return minimums, maximums
end

function vector_meta:SetLength(magnitude)
	---ARGUMENTS: number
	---RETURNS: self
	---Sets the vector's length.
	---This modifies the vector.
	self:Mul(magnitude / self:Length())

	return self 
end

function vector_meta:SetZeroes(zero)
	---ARGUMENTS: number
	---RETURNS: self
	---Sets all components of zero to the sepcified amount.
	---Unlike GetZeroed, this modifies the vector.
	for axis = 1, 3 do if self[axis] == 0 then self[axis] = zero end end

	return self
end

function vector_meta:TriangleNormal(second, third)
	---ARGUMENTS: Vector, Vector
	---RETURNS: Vector
	---Given two additional points, returns the normal of the created triangle.
	local normal = (second - self):Cross(third - self)

	normal:Normalize()

	return normal
end

function vector_meta:Truncate(digits)
	---ARGUMENTS: number=0
	---RETURNS: self
	---Round components towards zero.
	---This modifies the vector.
	digits = digits or 0

	self.x = math_Truncate(self.x, digits)
	self.y = math_Truncate(self.y, digits)
	self.z = math_Truncate(self.z, digits)

	return self
end

function vector_meta:WithMagnitude(magnitude)
	---ARGUMENTS: number
	---RETURNS: self
	---Returns a copied vector with the specified magnitude.
	return self * magnitude / self:Length()
end

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