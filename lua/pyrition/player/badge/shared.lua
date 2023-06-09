local _R = debug.getregistry()

local badge_meta = PYRITION.PlayerBadgeMeta or {}
local badge_public = _R.PyritionBadge or {__index = badge_meta, __name = "PyritionBadge"}
local badge_tier_meta = {TierFunctionsInstalled = true}

local function kieve_badge(_index, text, _text_data, _texts, _key_values, phrases)
	local ply = phrases.player

	if ply then
		local badge = PYRITION:PlayerBadgeGetInternal(ply, text) or PYRITION:PlayerBadgeGetTable(text)

		if badge then return badge:Name() end
	end
end

PYRITION.PlayerBadgeRegistry = PYRITION.PlayerBadgeRegistry or {}
PYRITION.PlayerBadges = PYRITION.PlayerBadges or {}
PYRITION.PlayerBadgeTieredMeta = badge_tier_meta
PYRITION.PlayerBadgeMeta = badge_meta
_R.PyritionBadge = badge_public

function badge_public:__tostring()
	local level = self.Level
	local ply = self.Player

	return "PyritionBadge [" .. self.Class .. (level and ":" .. level .. "]" or "]") .. (IsValid(ply) and "[" .. ply:Name() .. "<" .. ply:SteamID() .. ">]")
end

function badge_meta:BakeTiers()
	self:InstallTierFunctions()

	local materials = {}
	self.TierLevels = {}
	self.Tier = self:CalculateTier()
	self.TierMaterials = materials

	for tier, arguments in ipairs(self.Tiers) do
		local level, material_path

		--for tiers that match their levels
		if isstring(arguments) then level, material_path = tier, arguments
		else level, material_path = arguments[1], arguments[2] end

		self:BakeTier(tier, level, material_path)
	end

	self.Material = materials[1]
end

function badge_meta:GetMaterial() return self.Material end
function badge_meta:IncrementLevel(increment) self:SetLevel(self.Level + increment) end
function badge_meta:InstallTierFunctions() table.Merge(self, table.Copy(badge_tier_meta)) end
function badge_meta:Name() return language.GetPhrase("pyrition.badges." .. self.Class) end

function badge_meta:SetLevel(level, initial)
	if level and level < 1 then return self:PlayerBadgeRevoke(self.Player, class) end

	self.Level = level

	self:Sync()

	--initial is true if the badge is being loaded off the database
	if initial then return end

	local old_level = self.Level

	if self.OnLevelChanged and self:OnLevelChanged(old_level, level) then return end

	PYRITION:PlayerBadgeLevelChanged(self.Player, self, old_level, level)
end

function badge_meta:ShouldDisplay() if self.Level > 0 then return true end end
function badge_meta:Sync(who) if SERVER then PYRITION:PlayerBadgeSync(who or true, self) end end
function badge_meta:UpdateLevel(level) return self.Level ~= level and self:SetLevel(level) end

function badge_tier_meta:BakeTier(tier, level, material_path)
	self.TierLevels[tier] = level
	self.TierMaterials[tier] = Material(material_path)
end

function badge_tier_meta:CalculateTier(level)
	local level = level or self.Level

	for tier, requirement in ipairs(self.TierLevels) do
		if level >= requirement then
			return tier
		end
	end

	return 0
end

function badge_tier_meta:CalculateTierFrom(start_tier, level)
	--same as CalculateTier but skips over all tiers before start_tier in the calculation
	if start_tier < 1 then return self:CalculateTier(level) end

	local level = level or self.Level
	local tier_levels = self.TierLevels

	for tier = start_tier, #tier_levels do if level >= tier_levels[tier] then return tier end end

	return 0
end

function badge_tier_meta:Name() return language.GetPhrase("pyrition.badges." .. self.Class .. ".tier_" .. self.Tier) end

function badge_tier_meta:SetLevel(level, initial)
	if level and level < 1 then return self:PlayerBadgeRevoke(self.Player, class) end

	local old_level = self.Level
	local old_tier = self.Tier or 1
	local tier = level > old_level and self:CalculateTierFrom(self.Tier, level) or self:CalculateTier(level)

	self.Level = level
	self.Material = self.TierMaterials[tier]
	self.Tier = tier

	self:Sync()

	if initial then return level end --initial is true if the badge is being loaded off the database
	if self.OnLevelChanged and self:OnLevelChanged(old_level, level) then return level end --call override function

	PYRITION:PlayerBadgeLevelChanged(self.Player, self, old_level, level, old_tier, tier)

	return level
end

function PYRITION:PlayerBadgeExists(class) return self.PlayerBadgeRegistry[class] and true or false end

function PYRITION:PlayerBadgeGet(ply, class) --Returns the player's badge (if they have it, returns false for revoked badges)
	local badge = self:PlayerBadgeGetInternal(ply, class)

	if badge then return badge.Level > 0 and badge or false end
end

function PYRITION:PlayerBadgeGetInternal(ply, class) --Returns the player's badge (including revoked badges)
	local players_badges = self.PlayerBadges[ply]

	return players_badges and players_badges[class]
end

function PYRITION:PlayerBadgeGetTable(class) return self.PlayerBadgeRegistry[class] end --Returns the method table of the badge

function PYRITION:PlayerBadgeGive(ply, class, level, initial) --Used to give the player their badge
	if level and level < 1 then return self:PlayerBadgeRevoke(ply, class) end

	local badge = setmetatable(table.Merge({
		IsPyritionBadge = true,
		Level = level or 1,
		Player = ply
	}, self.PlayerBadgeRegistry[class]), badge_public)

	local players_badges = self.PlayerBadges[ply]

	if players_badges then players_badges[class] = badge
	else self.PlayerBadges[ply] = {[class] = badge} end

	if badge.Initialize then badge:Initialize(level) end --call Initialize method

	if level then badge:SetLevel(level, initial) --update level
	else badge:Sync() end --if we don't update the level, make sure we sync

	return badge
end

function PYRITION:PlayerBadgeIncrement(ply, class, increment) --Increase the level of the player's badge, giving them the badge if they don't have it
	local badge = self:PlayerBadgeSet(ply, class)

	badge:IncrementLevel(increment or 1)

	return badge
end

function PYRITION:PlayerBadgeRemove(ply, class) --Use PlayerBadgeRevoke instead, unless you know what you're doing
	local players_badges = self.PlayerBadges[ply]

	if players_badges then
		players_badges[class] = nil

		--clean up the badges table
		if table.IsEmpty(players_badges) then self.PlayerBadges[ply] = nil end
	end
end

function PYRITION:PlayerBadgeSet(ply, class, level, initial) --Set the level of a player's badge, or give it to them if they don't have it
	local current_badge = self:PlayerBadgeGetInternal(ply, class)
	local removing = level and level <= 0

	if current_badge then
		if current_badge.Level > 0 and not removing then return current_badge end

		--we need to recreate badge if it was removed
		self:PlayerBadgeRemove(ply, class)
	end

	if removing then return current_badge
	else return self:PlayerBadgeGive(ply, class, level, initial) end
end

function PYRITION:PlayerBadgesGet(ply) return self.PlayerBadges[ply] end --Returns a table of all badges the player owns

function PYRITION:PlayerBadgesGetGlint(ply)
	local badges = self:PlayerBadgesGet(ply)

	if not badges then return end

	local record_glint
	local record_weight = -1

	for class, badge in pairs(badges) do
		local glint = badge.PlayerGlint
		local glint_weight = badge.PlayerGlintWeight or 0

		if glint and glint_weight > record_weight then
			record_glint = glint
			record_weight = glint_weight
		end
	end

	return record_glint
end

function PYRITION:HOOK_PlayerBadgeRegister(class, badge, base_class)
	local base = self.PlayerBadgeRegistry[base_class]
	local material = badge.Material or "icon16/error.png"

	badge.Class = class
	badge.Material = isstring(material) and Material(material) or material

	--POST: nest Initialize functions like other meta tables?
	if base then badge = table.Merge(table.Copy(base), badge) end

	self.PlayerBadgeRegistry[class] = badge

	for ply, player_badges in pairs(self.PlayerBadges) do
		local this_badge = player_badges[class]

		if this_badge and this_badge.OnReloaded then
			--update functions
			for key, value in pairs(badge) do if isfunction(value) then this_badge[key] = value end end

			this_badge:OnReloaded()
		end
	end

	--server side task
	if SERVER then self:NetAddEnumeratedString("PyritionBadge", class) end

	return badge
end

PYRITION:GlobalHookCreate("PlayerBadgeRegister")
PYRITION:LanguageRegisterColor("misc", "badge", "level", "tier")
PYRITION:LanguageRegisterKieve(kieve_badge, "badge")