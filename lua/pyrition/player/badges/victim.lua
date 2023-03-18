--locals
local BADGE = {
	Level = 0,

	Tiers = {
		{200, "icon16/cross.png"},
		{1000, "icon16/cross.png"},
		{2000, "icon16/cross.png"},
		{10000, "icon16/cancel.png"},
		{20000, "icon16/cut_red.png"}
	}
}

language.Add("pyrition.badges.victim", "Victim")
language.Add("pyrition.badges.victim.description", "Badge granted for dying... a lot...")
language.Add("pyrition.badges.victim.tier_1", "Common Casualty")
language.Add("pyrition.badges.victim.tier_2", "Frequent Casualty")
language.Add("pyrition.badges.victim.tier_3", "Victim")
language.Add("pyrition.badges.victim.tier_4", "Targetted Victim")
language.Add("pyrition.badges.victim.tier_5", "Death Enthusiast")

--badge functions
function BADGE:Initialize() self:BakeTiers() end
function BADGE:OnReloaded() self:BakeTiers() end

--post
PYRITION:PlayerBadgeRegister("victim", BADGE)