--locals
local BADGE = {
	Level = 0,
	
	Tiers = {
		{100, "icon16/user_orange.png"},
		{500, "icon16/user_red.png"},
		{1000, "icon16/user_gray"},
		{5000, "icon16/gun.png"},
		{10000, "icon16/world_delete.png"}
	}
}

language.Add("pyrition.badges.killer", "Killer")
language.Add("pyrition.badges.killer.description", "Badge granted for killing a lot of players.")
language.Add("pyrition.badges.killer.tier_1", "Killer")
language.Add("pyrition.badges.killer.tier_2", "Muderer")
language.Add("pyrition.badges.killer.tier_3", "Executor")
language.Add("pyrition.badges.killer.tier_4", "Exterminator")
language.Add("pyrition.badges.killer.tier_5", "Genocider")

--local functions
local function attempt_increment(victim, attacker)
	if attacker:IsNPC() then return end --ignore npcs
	if victim == attacker then return end --no suicides
	
	if attacker:IsPlayer() then
		--don't allow players to farm bots
		--if victim:IsBot() and not attacker:IsBot() then return false end --RELEASE: re-enable this
		
		PYRITION:PlayerBadgeIncrement(attacker, "killer")
		
		return true
	end
end

local function attempt_increments(victim, attacker)
	if IsValid(attacker) then
		if attempt_increment(victim, attacker) then return true
		else
			local owner = attacker:GetOwner()
			
			if IsValid(owner) and attempt_increment(victim, owner) then return true
			elseif attacker:IsVehicle() then
				local driver = attacker:GetDriver()
				
				if IsValid(driver) and attempt_increment(victim, driver) then return true end
			end
		end
	end
end

--badge functions
function BADGE:Initialize() self:BakeTiers() end

function BADGE:OnLevelChanged(_old_level, level)
	local tier = self.Tier
	local next_level = self.TierLevels[tier + 1]
	
	if next_level then
		PYRITION:LanguageQueue(self.Player, "[:level] / [:next_level] kills", {
			next_level = tostring(next_level),
			level = tostring(level)
		}, "killer_badge")
		
		return
	end
	
	PYRITION:LanguageQueue(self.Player, "[:level] total kills", {level = tostring(level)}, "killer_badge")
	
	return true
end

function BADGE:OnReloaded() self:BakeTiers() end

--hooks
hook.Add("PlayerDeath", "PyritionPlayerBadgesKiller", function(victim, inflictor, attacker)
	if IsValid(victim) and IsValid(attacker) then
		if attempt_increments(victim, attacker) then return end --attempt to award the attacker
		if attempt_increments(victim, inflictor) then return end --attempt to award the inflictor
	end
end)

--post
PYRITION:LanguageRegisterOption("killer_badge", function(formatted, _key, _phrases)
	--RELEASE: make this show up as a really cool tooltip instead of a chat message
	chat.AddText(Color(255, 192, 0), "[killer_badge] ", color_white, formatted)
end)

PYRITION:PlayerBadgeRegister("killer", BADGE)