--locals
local BADGE = {
	DontSave = false,
	Glint = Color(255, 128, 64),
	Material = "icon16/fire.png",
	Removable = false,
	
	Tiers = {
		"icon16/asterisk_yellow.png", --1 motivation
		"icon16/asterisk_orange.png", --2 gave input
		"icon16/award_star_bronze_1.png", --3 minor correction (typo)
		"icon16/award_star_bronze_3.png", --4 tested
		"icon16/award_star_bronze_2.png", --5 tested a lot
		"icon16/award_star_silver_3.png", --6 localizations
		"icon16/award_star_silver_2.png", --7 lots of localizations
		"icon16/award_star_silver_1.png", --8 assisted in creating code
		"icon16/award_star_gold_3.png", --9 made a pr, gave a code sample, etc.
		"icon16/award_star_gold_2.png", --10 made a valuable pr
		"icon16/award_star_gold_1.png" --11 made several valuable prs
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