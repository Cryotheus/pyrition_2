--locals
local path_follower_meta = FindMetaTable("PathFollower")

--meta functions
function path_follower_meta:GetDeduplicatedSegments()
	---Same as PathFollower:GetAllSegments, but removes any segments that are in the same area as the previous segment.
	local index = 2
	local segments = self:GetAllSegments()

	table.remove(segments, 1)

	local segments_count = #segments

	if segments_count > 1 and segments[segments_count].area == segments[segments_count - 1].area then
		segments_count = segments_count - 1
		segments[segments_count] = nil
	end

	while index <= segments_count do
		local last_segment = segments[index - 1]
		local segment = segments[index]

		if segment.area == last_segment.area then
			segments_count = segments_count - 1

			table.remove(segments, index - 1)
		else index = index + 1 end
	end

	return segments
end