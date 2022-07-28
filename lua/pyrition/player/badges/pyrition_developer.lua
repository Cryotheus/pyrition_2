local BADGE = {Material = "icon16/fire.png"}

language.Add("pyrition.badges.pyrition_developer", "Pyrition Developer")
language.Add("pyrition.badges.pyrition_developer.description", "I made this! Commit 1000 lines of code to the Pyrition repository to get this badge.")

--badge functions
function BADGE:OnLevelChanged() return true end

--post
PYRITION:PlayerBadgeRegister("pyrition_developer", BADGE)