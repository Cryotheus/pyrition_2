--[[-Take control of hibernation thinking properly!
When anything needs hibernation thinking (see console variable `sv_hibernate_think`)
you can use $$PYRITION:HibernateWake to inform Pyrition hibernation thinking is needed.
When your code no longer needs hibernation thinking, call $$PYRITION:Hibernate with the same key to allow the server to hibernate.]]

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
	---ARGUMENTS: string, boolean=nil
	---SEE: PYRITION:HibernateWake
	---Disables hibernation thinking once this has been called for all keys.
	---Setting state to false (not nil!) is the same as calling $$PYRITION:HibernateWake.
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
	---ARGUMENTS: number, function
	---SEE: PYRITION:HibernateWake
	---A timer which will cause the server to think during hibernation until the timer has elapsed.
	if self.HibernateTimers == 0 then
		self.HibernateTimers = 1

		self:HibernateWake("PyritionHibernateSafeTimers")
	else self.HibernateTimers = self.HibernateTimers + 1 end

	timer.Simple(delay, function()
		if self.HibernateTimers == 1 then
			self.HibernateTimers = 0

			self:Hibernate("PyritionHibernateSafeTimers")
		else self.HibernateTimers = self.HibernateTimers - 1 end

		callback()
	end)
end

function PYRITION:HibernateSafeZeroTimer(callback)
	---ARGUMENTS: function
	---SEE: PYRITION:HibernateSafeTimer
	---Exactly the same as calling $$PYRITION:HibernateSafeTimer with the delay set to 0.
	self:HibernateSafeTimer(0, callback)
end

function PYRITION:HibernateWake(key)
	---ARGUMENTS: string
	---SEE: PYRITION:Hibernate
	---Enables hibernation thinking if not already enabled.
	---Use a unique string for $key and when you no longer need hibernation thinking call $$PYRITION:Hibernate.
	self:Hibernate(key, false)
end

function PYRITION:Hibernating()
	---RETURNS: boolean
	---Returns true if hibernation thinking is enabled.
	return next(hibernation_registry) == nil
end

--convars
cvars.AddChangeCallback("pyrition_hibernate_think", update_hibernate_think, "PyritionHibernate")

--post
update_hibernate_think()