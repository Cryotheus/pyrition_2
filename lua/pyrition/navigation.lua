--locals
local area_indices = PYRITION.NavigationAreaIndices or {}
local area_list = PYRITION.NavigationAreaList or {}
local setup_patience = 60 --how long until we timeout for doing navmesh setup
local setup_wait

--globals
PYRITION.NavigationAreaIndices = area_indices
PYRITION.NavigationAreaList = area_list

--pyrition functions
function PYRITION:NavigationSetup()
	local last_index = 1

	table.Empty(area_indices)
	table.Empty(area_list)

	for index, area in ipairs(navmesh.GetAllNavAreas()) do
		local area_index = area:GetID()
		area_list[area] = area_index
		area_list[area_index] = area

		table.insert(area_indices, area_index)

		--we don't want gaps
		for fill_index = area_index - 1, last_index + 1, -1 do area_list[fill_index] = false end

		last_index = area_index
	end
end

function PYRITION:NavigationSetupTimeout()
	--LOCALIZE: navmesh timeout message
	self:LanguageDisplay("navigation", "The navigation mesh failed to load in time. Did you forget to generate it?")
end

--hooks
if not next(PYRITION.NavigationAreaList) or navmesh.IsLoaded() and navmesh.GetNavAreaCount() == 0 then
	PYRITION:HibernateWake("PyritionNavigation")

	--PYRITION.InitPostEntity
	hook.Add("Tick", "PyritionNavigation", function()
		if not PYRITION.InitPostEntity then --wait until the map has loaded fully
		elseif navmesh.IsLoaded() then
			hook.Remove("Tick", "PyritionNavigation")

			PYRITION:Hibernate("PyritionNavigation")
			PYRITION:NavigationSetup()
		elseif setup_wait then
			if CurTime() > setup_wait then
				hook.Remove("Tick", "PyritionNavigation")
				PYRITION:NavigationSetupTimeout()
			end
		else setup_wait = CurTime() + setup_patience end
	end)
end
