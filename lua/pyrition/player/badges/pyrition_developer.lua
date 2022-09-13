--locals
local BADGE = {
	DontSave = false,
	Material = "icon16/fire.png"
}

language.Add("pyrition.badges.pyrition_developer", "Pyrition Developer")
language.Add("pyrition.badges.pyrition_developer.description", "I made Pyrition!")

--badge functions
function BADGE:OnLevelChanged() return true end

--post
PYRITION:PlayerBadgeRegister("pyrition_developer", BADGE)