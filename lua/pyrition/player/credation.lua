local short_steam_id = PYRITION._SignificantDigitSteamID

PYRITION.Credation = {
	BOT = {Badges = {"bot"}}, --bots for just being amazing, literally making testers almost irrelevant
	["172956761"] = {Badges = {"pyrition_developer"}}, --me (Cryotheum) the developer of Pyrition
	["166057978"] = {Badges = {{"pyrition_contributor", 9}}}, --Yogpod for giving me sources to resolve many issues
	["1100559239"] = {Badges = {{"pyrition_contributor", 7}}}, --Gin for lots of localizations
	["054851650"] = {Badges = {{"pyrition_contributor", 2}}}, --Sprice for concepts and motivation, and code input
	["155182203"] = {Badges = {"pyrition_contributor"}}, --Dagaz for concepts and motivation, and design input
	["091921853"] = {Badges = {"pyrition_contributor"}}, --PCrafterZ previous server dev, gave input on code
}

--Color(76, 254, 83) --lime scout green --sprice
--Color(252, 42, 55) --dishonorable red --dagaz

function PYRITION:PlayerCredationGet(ply) return self.Credation[ply:IsBot() and "BOT" or short_steam_id(ply)] or false end

function PYRITION:PlayerCredationGetBadges(ply)
	local credation = self:PlayerCredationGet(ply)

	return credation and credation.Badges
end

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
