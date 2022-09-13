--locals
local _R = debug.getregistry()

--local tables
local badge_meta = PYRITION.PlayerBadgeMeta or {}

local badge_public = {__index = badge_meta, __name = "PyritionBadge"}
local badge_tier_meta = {TierFunctionsInstalled = true}

--local functions
local function kieve_badge(_index, text, _text_data, _texts, _key_values, phrases)
	local ply = phrases.player
	
	if ply then
		local badge = PYRITION:PlayerBadgeGet(ply, text)
		
		if badge then return badge:Name() end
	end
end

--globals
PYRITION.PlayerBadgeRegistry = PYRITION.PlayerBadgeRegistry or {}
PYRITION.PlayerBadges = PYRITION.PlayerBadges or {}
PYRITION.PlayerBadgeTieredMeta = badge_tier_meta
PYRITION.PlayerBadgeMeta = badge_meta
_R.PyritionBadge = badge_public

--badge meta functions
function badge_public:__tostring() return "PyritionBadge [" .. self.Class .. "]" end

function badge_meta:BakeTiers()
	self:InstallTierFunctions()
	
	local materials = {}
	self.TierLevels = {}
	self.Tier = self:CalculateTier()
	self.TierMaterials = materials
	
	for tier, arguments in ipairs(self.Tiers) do self:BakeTier(tier, unpack(arguments)) end
	
	self.Material = materials[1]
end

function badge_meta:IncrementLevel(increment) self:SetLevel(self.Level + increment) end
function badge_meta:InstallTierFunctions() table.Merge(self, table.Copy(badge_tier_meta)) end
function badge_meta:GetMaterial(_level) return self.Material end
function badge_meta:Name() return language.GetPhrase("pyrition.badges." .. self.Class) end

function badge_meta:SetLevel(level, initial)
	self.Level = level
	
	--initial is true if the badge is being loaded off the database
	if initial then return end
	
	local old_level = self.Level
	
	if self.OnLevelChanged and self:OnLevelChanged(old_level, level) then return end
	
	PYRITION:PlayerBadgeLevelChanged(self.Player, self, old_level, level)
end

function badge_meta:ShouldDisplay() if self.Level > 0 then return true end end

--badge tier meta functions
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
	local old_level = self.Level
	local old_tier = self.Tier or 1
	local tier = level > old_level and self:CalculateTierFrom(self.Tier, level) or self:CalculateTier(level)
	
	self.Level = level
	self.Material = self.TierMaterials[tier]
	self.Tier = tier
	
	--initial is true if the badge is being loaded off the database
	if initial then return end
	
	--call override function
	if self.OnLevelChanged and self:OnLevelChanged(old_level, level) then return end
	
	PYRITION:PlayerBadgeLevelChanged(self.Player, self, old_level, level, old_tier, tier)
end

--pyrition functions
function PYRITION:PlayerBadgeExists(class) return self.PlayerBadgeRegistry[class] and true or false end

function PYRITION:PlayerBadgeGet(ply, class)
	local players_badges = self.PlayerBadges[ply]
	
	return players_badges and players_badges[class]
end

function PYRITION:PlayerBadgeGetTable(class) return self.PlayerBadgeRegistry[class] end

function PYRITION:PlayerBadgeGive(ply, class, level, initial)
	local current_badge = self:PlayerBadgeGet(ply, class)
	
	if current_badge then
		if current_badge.Level > 0 then return current_badge end
		
		self:PlayerBadgeRemove(ply, class)
		
		return self:PlayerBadgeSet(ply, class, level, initial)
	end
	
	return false
end

function PYRITION:PlayerBadgeIncrement(ply, class, increment)
	local badge = self:PlayerBadgeGive(ply, class)
	
	badge:IncrementLevel(increment or 1)
	
	return badge
end

function PYRITION:PlayerBadgeRemove(ply, class) --Use PlayerBadgeRevoke instead, unless you know what you are doing
	local players_badges = self.PlayerBadges[ply]
	
	if players_badges then players_badges[class] = nil end
end

function PYRITION:PlayerBadgeRevoke(ply, class)
	local badge = self:PlayerBadgeGet(ply, class)
	
	if badge then
		table.Empty(badge)
		
		badge.Class = class
		badge.Player = ply
		badge.Level = 0 --we mark this badge for removal
	end
end

function PYRITION:PlayerBadgeSet(ply, class, level, initial)
	if level and level < 1 then return self:PlayerBadgeRevoke(ply, class) end
	
	local badge = setmetatable(table.Merge({
		IsPyritionBadge = true,
		Level = level or 1,
		Player = ply
	}, self.PlayerBadgeRegistry[class]), badge_public)
	
	local players_badges = self.PlayerBadges[ply]
	
	if players_badges then players_badges[class] = badge
	else self.PlayerBadges[ply] = {[class] = badge} end
	
	if badge.Initialize then badge:Initialize(level) end
	if level then badge:SetLevel(level, initial) end
	
	return badge
end

function PYRITION:PlayerBadgesGet(ply) return self.PlayerBadges[ply] end

--pyrition hooks
function PYRITION:PyritionPlayerBadgeRegister(class, badge, base_class)
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
	
	return badge
end

function PYRITION:PyritionPlayerBadgeLevelChanged(ply, badge, old_level, level, old_tier, tier)
	if old_tier then
		if tier < 1 or tier <= old_tier then return end
		
		self:LanguageQueue(ply, "[:player:you=Your:possessive=en] [:badge] badge has tiered up to tier [:tier].", {
			badge = badge.Class,
			tier = tostring(tier),
			player = ply,
		})
	else
		if level < 1 or level <= old_level then return end
		
		self:LanguageQueue(ply, "[:player:you=Your:possessive=en] [:badge] badge has levelled up to level [:level].", {
			badge = badge.Class,
			level = tostring(level),
			player = ply,
		})
	end
end

--post
PYRITION:GlobalHookCreate("PlayerBadgeRegister")
PYRITION:LanguageRegisterColor("misc", "badge", "level", "tier")
PYRITION:LanguageRegisterKieve(kieve_badge, "badge")