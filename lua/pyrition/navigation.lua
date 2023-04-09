--locals
local area_indices = PYRITION.NavigationAreaIndices or {}
local area_list = PYRITION.NavigationAreaList or {}
local setup_patience = 60 --how long until we timeout for doing navmesh setup
local setup_wait

--globals
PYRITION.NavigationAreaIndices = area_indices
PYRITION.NavigationAreaList = area_list

--pyrition functions
function PYRITION:NavigationSetupTimeout()
	--LOCALIZE: navmesh timeout message
	self:LanguageDisplay("navigation", "The navigation mesh failed to load in time. Did you forget to generate it?")
end

function PYRITION:NavigationSetup()
	table.Empty(area_indices)
	table.Empty(area_list)

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
if not next(PYRITION.NavigationAreaList) or navmesh.IsLoaded() and navmesh.GetNavAreaCount() == 0 then
	hook.Add("Tick", "PyritionNavigationSetup", function()
		if navmesh.IsLoaded() then
			hook.Remove("Tick", "PyritionNavigationSetup")
			PYRITION:NavigationSetup()
		elseif setup_wait then
			if CurTime() > setup_wait then
				hook.Remove("Tick", "PyritionNavigationSetup")
				PYRITION:NavigationSetupTimeout()
			end
		else setup_wait = CurTime() + setup_patience end
	end)
end