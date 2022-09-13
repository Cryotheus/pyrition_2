--locals
local BADGE = {
	DontSave = false,
	Glint = Color(255, 128, 64),
	Material = "icon16/fire.png",
	Removable = false,
	
	Tiers = {
		"icon16/asterisk_yellow.png", --motivation
		"icon16/asterisk_orange.png", --gave input
		"icon16/award_star_bronze_1.png", --minor correction (typo)
		"icon16/award_star_bronze_3.png", --tested
		"icon16/award_star_bronze_2.png", --tested a lot
		"icon16/award_star_silver_3.png", --localizations
		"icon16/award_star_silver_2.png", --lots of localizations
		"icon16/award_star_silver_1.png", --assisted in creating code
		"icon16/award_star_gold_3.png", --made a pr, gave a code sample, etc.
		"icon16/award_star_gold_2.png", --made a valuable pr
		"icon16/award_star_gold_1.png" --made several valuable prs
	}
}

language.Add("pyrition.badges.pyrition_contributor", "Pyrition Contributor")
language.Add("pyrition.badges.pyrition_contributor.description", "I contributed to the development of Pyrition!")

--badge functions
function BADGE:Initialize() self:BakeTiers() end
function BADGE:Name() return language.GetPhrase("pyrition.badges.pyrition_contributor") end
function BADGE:OnReloaded() self:BakeTiers() end

--post
PYRITION:PlayerBadgeRegister("pyrition_contributor", BADGE)