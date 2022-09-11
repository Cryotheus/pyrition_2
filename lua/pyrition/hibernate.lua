--locals
local pyrition_hibernate_think = CreateConVar("pyrition_hibernate_think", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_NEVER_AS_STRING), language.GetPhrase("pyrition.convars.pyrition_hibernate_think"))
local hibernation_registry = PYRITION.HibernateRegistry or {}
--local sv_hibernate_think = GetConVar("sv_hibernate_think") --we used to check this before we updated it, but GetBool/GetInt was returning the wrong values

--local functions
local function update_hibernate_think()
	if pyrition_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 1)
	else RunConsoleCommand("sv_hibernate_think", PYRITION:Hibernating() and 0 or 1) end
end

--globals
PYRITION.HibernateRegistry = hibernation_registry

--pyrition functions
function PYRITION:Hibernate(key, state) --Toggles hibernation thinking
	if state ~= false then
		hibernation_registry[key] = nil
		
		--hibernate if possible
		if table.IsEmpty(hibernation_registry) and not pyrition_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 0) end
		
		return
	end
	
	hibernation_registry[key] = true
	
	RunConsoleCommand("sv_hibernate_think", 1)
end

function PYRITION:HibernateWake(key) self:Hibernate(key, false) end --Enables hibernation thinking
function PYRITION:Hibernating() return next(hibernation_registry) == nil end

--convars
cvars.AddChangeCallback("pyrition_hibernate_think", update_hibernate_think, "PyritionHibernate")

--post
update_hibernate_think()