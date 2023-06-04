--locals
local nav_area_meta = FindMetaTable("CNavArea")

--local tables
local area_direction_rights = {
	[PYRITION_NAV_DIR_EAST] = Vector(-1, 0, 0),
	[PYRITION_NAV_DIR_NORTH] = Vector(0, -1, 0),
	[PYRITION_NAV_DIR_SOUTH] = Vector(1, 0, 0),
	[PYRITION_NAV_DIR_WEST] = Vector(0, 1, 0),
}

local area_direction_right_axes = {
	[PYRITION_NAV_DIR_EAST] = 1,
	[PYRITION_NAV_DIR_NORTH] = 2,
	[PYRITION_NAV_DIR_SOUTH] = 1,
	[PYRITION_NAV_DIR_WEST] = 2,
}

local area_direction_forwards = {
	[PYRITION_NAV_DIR_EAST] = Vector(0, -1, 0),
	[PYRITION_NAV_DIR_NORTH] = Vector(1, 0, 0),
	[PYRITION_NAV_DIR_SOUTH] = Vector(0, 1, 0),
	[PYRITION_NAV_DIR_WEST] = Vector(-1, 0, 0),
}

local area_direction_forward_axes = {
	[PYRITION_NAV_DIR_EAST] = 2,
	[PYRITION_NAV_DIR_NORTH] = 1,
	[PYRITION_NAV_DIR_SOUTH] = 2,
	[PYRITION_NAV_DIR_WEST] = 1,
}

--meta functions
function nav_area_meta:CalculatePortalSegment(target)
	---ARGUMENTS: CNavArea
	---RETURNS: Vector "Left end of segment.", Vector "Right end of segment."
	---Calculates three vectors representing a segment of the shared edge between two areas.
	---The first vector returned is always the right end of the segment from the source area.
	local source_center = self:GetCenter()
	local source_dimension_x = self:GetSizeX()
	local source_dimension_y = self:GetSizeY()
	local source_size = Vector(source_dimension_x, source_dimension_y)
	local target_center = target:GetCenter()
	local target_dimension_x = target:GetSizeX()
	local target_dimension_y = target:GetSizeY()
	local target_edge_position = target:GetClosestPointOnArea(source_center)
	local target_size = Vector(target_dimension_x, target_dimension_y, 0)

	local direction = self:ComputeDirection(target_edge_position)
	local portal_forward = area_direction_forwards[direction]
	local portal_forward_axis = area_direction_forward_axes[direction]
	local portal_right_axis = area_direction_right_axes[direction]
	local portal_right_half = area_direction_rights[direction] * 0.5
	local source_edge_center = source_size * portal_forward + target_center
	local source_edge_left = source_size * -portal_right_half + source_edge_center
	local source_edge_right = source_size * portal_right_half + source_edge_center
	local target_edge_center = target_size * -portal_forward + target_center
	local target_edge_left = target_size * -portal_right_half + target_edge_center
	local target_edge_right = target_size * portal_right_half + target_edge_center

	local segment_left = Vector()
	local segment_right = Vector()

	segment_left[portal_forward_axis] = source_edge_center[portal_forward_axis]
	segment_left[portal_right_axis] = math.min(source_edge_left[portal_right_axis], target_edge_left[portal_right_axis])

	segment_right[portal_forward_axis] = source_edge_center[portal_forward_axis]
	segment_right[portal_right_axis] = math.max(source_edge_right[portal_right_axis], target_edge_right[portal_right_axis])

	local segment_z = target:GetClosestPointOnArea((segment_left + segment_right) * 0.5)

	segment_left[3] = segment_z
	segment_right[3] = segment_z

	return segment_left, segment_right
end
