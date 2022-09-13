--locals
local short_steam_id = PYRITION._SignificantDigitSteamID

--globals
PYRITION.Credation = {
	["BOT"] = {Badges = {"bot"}},
	["172956761"] = {Badges = {"pyrition_developer"}}
}

--pyrition functions
function PYRITION:PlayerCredationGet(ply) return self.Credation[ply:IsBot() and "BOT" or short_steam_id(ply)] or false end

function PYRITION:PlayerCredationGetBadges(ply)
	local credation = self:PlayerCredationGet(ply)
	
	return credation and credation.Badges
end

--hooks
hook.Add("PyritionPlayerBadgesLoaded", "PyritionPlayerCredation", function(ply)
	local badges = PYRITION:PlayerCredationGetBadges(ply)
	
	if not badges then return end
	
	for index, class in ipairs(badges) do
		local level
		
		--if we are a class level pair, correct the variables
		if istable(class) then class, level = class[1], class[2] end
		
		--we use initial since we are acting like we are loading from the database
		PYRITION:PlayerBadgeSet(ply, class, level, true)
	end
end)
