--locals
local area_indices = PYRITION.NavigationAreaIndices or {}
local area_list = PYRITION.NavigationAreaList or {}

--globals
PYRITION.NavigationAreaIndices = area_indices
PYRITION.NavigationAreaList = area_list

--pyrition functions
function PYRITION:NavigationSetup()
	--the navmesh must be loaded for us to get the areas
	if not navmesh.IsLoaded() then navmesh.Load() end

	for index = 1, navmesh.GetNavAreaCount() do
		local area = navmesh.GetNavAreaByID(index)

		if area then
			table.insert(area_indices, index)

			area_list[area] = index
			area_list[index] = area
		else area_list[index] = false end --we don't want gaps
	end
end

--hooks
hook.Add("InitPostEntity", "PyritionNavigationSetup", function() PYRITION:NavigationSetup() end)