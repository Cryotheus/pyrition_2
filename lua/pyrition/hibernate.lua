--locals
local hibernation_registry = PYRITION.HibernateRegistry or {}
local pyrition_hibernate_think = CreateConVar("pyrition_hibernate_think", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_NEVER_AS_STRING), language.GetPhrase("pyrition.convars.pyrition_hibernate_think"))


--local functions
local function update_hibernate_think()
	if pyrition_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 1)
	else RunConsoleCommand("sv_hibernate_think", PYRITION:Hibernating() and 0 or 1) end
end

--globals
PYRITION.HibernateRegistry = hibernation_registry
PYRITION.HibernateTimers = PYRITION.HibernateTimers or 0

--pyrition functions
function PYRITION:Hibernate(key, state)
	---TYPES: string, boolean=nil
	---Disables hibernation thinking once this has been called for all keys.
	---Setting state to false (not nil!) is the same as calling HibernateWake.
	if state ~= false then
		hibernation_registry[key] = nil

		--hibernate if possible
		if table.IsEmpty(hibernation_registry) and not pyrition_hibernate_think:GetBool() then RunConsoleCommand("sv_hibernate_think", 0) end

		return
	end

	hibernation_registry[key] = true

	RunConsoleCommand("sv_hibernate_think", 1)
end

function PYRITION:HibernateSafeTimer(delay, callback)
	if self.HibernateTimers == 0 then
		self.HibernateTimers = 1

		self:HibernateWake("HibernateSafeTimers")
	else self.HibernateTimers = self.HibernateTimers + 1 end

	timer.Simple(delay, function()
		if self.HibernateTimers == 1 then
			self.HibernateTimers = 0

			self:Hibernate("HibernateSafeTimers")
		else self.HibernateTimers = self.HibernateTimers - 1 end

		callback()
	end)
end

function PYRITION:HibernateSafeZeroTimer(callback) self:HibernateSafeTimer(0, callback) end
function PYRITION:HibernateWake(key) self:Hibernate(key, false) end ---Enables hibernation thinking.
function PYRITION:Hibernating() return next(hibernation_registry) == nil end ---Returns true if hibernation thinking is enabled.

--convars
cvars.AddChangeCallback("pyrition_hibernate_think", update_hibernate_think, "PyritionHibernate")

--post
update_hibernate_think()