--locals
local area_indices = PYRITION.NavigationAreaIndices or {}
local area_list = PYRITION.NavigationAreaList or {}

--globals
PYRITION.NavigationAreaIndices = area_indices
PYRITION.NavigationAreaList = area_list

--pyrition functions
function PYRITION:PyritionNavigationSetup()
	table.Empty(area_indices)
	table.Empty(area_list)

	for index = 1, navmesh.GetNavAreaCount() do
		local area = navmesh.GetNavAreaByID(index)

		if area then
			table.insert(area_indices, index)

			area_list[area] = index
			area_list[index] = area
		else area_list[index] = false end
	end
end

--hooks
hook.Add("InitPostEntity", "PyritionNavigationSetup", function() PYRITION:NavigationSetup() end)