--locals
local pyrition_hibernate_think = CreateConVar("pyrition_hibernate_think", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_NEVER_AS_STRING), language.GetPhrase("pyrition.convars.pyrition_hibernate_think"))
local hibernation_registry = PYRITION.HibernateRegistry or {}
local sv_hibernate_think = GetConVar("sv_hibernate_think")

--local functions
local function update_hibernate_think()
	if pyrition_hibernate_think:GetBool() then
		if not sv_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 1) end
		
		return
	end
	
	if PYRITION:Hibernating() and sv_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 0) end
end

--globals
PYRITION.HibernateRegistry = hibernation_registry

--pyrition functions
function PYRITION:Hibernate(key, state) --Toggles hibernation thinking
	state = state == nil or state
	
	if state then
		hibernation_registry[key] = nil
		
		--hibernate if possible
		if table.IsEmpty(hibernation_registry) and sv_hibernate_think:GetBool() and not pyrition_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 0) end
		
		return
	end
	
	hibernation_registry[key] = true
	
	--if we are already thinking, don't update the convar
	if sv_hibernate_think:GetBool() then return end
	
	RunConsoleCommand("sv_hibernate_think", 1)
end

function PYRITION:Hibernating() return next(hibernation_registry) == nil end

--convars
cvars.AddChangeCallback("pyrition_hibernate_think", update_hibernate_think, "PyritionHibernate")

--post
update_hibernate_think()