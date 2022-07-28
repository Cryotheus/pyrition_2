--locals
local badge_registry = PYRITION.PlayerBadgeRegistry or {}
local badges = PYRITION.PlayerBadges or {}
local _R = debug.getregistry()

--globals
PYRITION.PlayerBadges = badges
PYRITION.PlayerBadgeRegistry = badge_registry

--local tables
local badge_meta = {
	IsPyritionBadge = true,
	Level = 0
}

local badge_public = {__index = badge_meta, __name = "PyritionBadge"}
local badge_tier_meta = {TierFunctionsInstalled = true}

--globals
PYRITION.PlayerBadgeTieredMeta = badge_tier_meta
_R.PyritionBadge = badge_public

--meta functions
function badge_public:__add(alpha, bravo)
	print(self, alpha, bravo)
	
	return self or alpha
end

function badge_public:__tostring() return "PyritionBadge [" .. self.Class .. "]" end

function badge_meta:BakeTiers()
	self:InstallTierFunctions()
	
	local materials = {}
	local tier = self:CalculateTier()
	
	self.Tier = tier
	self.TierLevels = {}
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

--tier meta functions
function badge_tier_meta:BakeTier(_tier, level, material_path)
	table.insert(self.TierLevels, level)
	table.insert(self.TierMaterials, Material(material_path))
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
	local level = level or self.Level
	local tier_levels = self.TierLevels
	
	for tier = start_tier, #tier_levels do if level >= tier_levels[tier] then return tier end end
	
	return 0
end

function badge_meta:Name() return language.GetPhrase("pyrition.badges." .. self.Class .. ".tier_" .. self.Tier) end

function badge_tier_meta:SetLevel(level)
	local old_level = self.Level
	local tier = level > old_level and self:CalculateTierFrom(self.Tier, level) or self:CalculateTier(level)
	
	self.Level = level
	self.Material = self.TierMaterials[tier]
	self.Tier = tier
	
	--call override function
	if self.OnLevelChanged and self:OnLevelChanged(old_level, level) then return end
	
	PYRITION:PlayerBadgeLevelChanged(self.Player, self, old_level, level)
end

--pyrition functions
function PYRITION:PlayerBadgeExists(class) return badge_registry[class] and true or false end

function PYRITION:PlayerBadgeGet(ply, class)
	local players_badges = badges[ply]
	
	return players_badges[class]
end

function PYRITION:PlayerBadgeGive(ply, class, level) return self:PlayerBadgeGet(ply, class) or self:PlayerBadgeSet(ply, class, level) end

function PYRITION:PlayerBadgeIncrement(ply, class, increment)
	local badge = self:PlayerBadgeGive(ply, class)
	
	badge:IncrementLevel(increment or 1)
	
	return badge
end

function PYRITION:PlayerBadgeSet(ply, class, level, initial)
	local badge = setmetatable(
		table.Merge(
			{Player = ply},
			badge_registry[class]
		),
		
		badge_public
	)
	
	local players_badges = badges[ply]
	
	if players_badges then players_badges[class] = badge
	else badges = {[ply] = badge} end
	
	if badge.Initialize then badge:Initialize(level) end
	if level then badge:SetLevel(level, initial) end
	
	return badge
end

--pyrition hooks
function PYRITION:PyritionPlayerBadgeRegister(class, badge, base_class)
	local base = badge_registry[base_class]
	local material = badge.Material or "icon16/error.png"
	
	badge.Class = class
	badge.Material = isstring(material) and Material(material) or material
	
	--POST: nest Initialize functions like other meta tables?
	if base then badge = table.Merge(table.Copy(base), badge) end
	
	badge_registry[class] = setmetatable(badge, badge_public)
	
	return badge
end

function PYRITION:PyritionPlayerBadgeLevelChanged(ply, badge, old_level, level)
	if level <= old_level then return end
	
	self:LanguageQueue(ply, "[:player:you=Your:possesive=en] [:badge] badge has levelled up to level [:level].", {
		badge = badge.Class,
		level = tostring(level),
		player = ply,
	})
end

--post
PYRITION:GlobalHookCreate("PlayerBadgeRegister")