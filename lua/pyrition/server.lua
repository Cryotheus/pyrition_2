function PYRITION._RecipientIterable(object)
	if object == true then return player.GetAll()
	elseif IsEntity(object) then return {object}
	elseif type(recipients) == "CRecipientFilter" then return recipients:GetPlayers()
	elseif istable(object) then return object end

	return false
end