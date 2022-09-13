--locals
local BADGE = {
	DontSave = false,
	Glint = Color(255, 128, 64),
	Material = "icon16/fire.png",
	PlayerGlint = Color(255, 128, 64),
	PlayerGlintWeight = 100,
	Removable = false
}

language.Add("pyrition.badges.pyrition_developer", "Pyrition Developer")
language.Add("pyrition.badges.pyrition_developer.description", "I made Pyrition!")

--post
PYRITION:PlayerBadgeRegister("pyrition_developer", BADGE)