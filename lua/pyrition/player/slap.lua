--to keep the authentic slap feel, a lot of this was yoinked from ulib
local slap_sounds = {
	"physics/body/body_medium_impact_hard1.wav",
	"physics/body/body_medium_impact_hard2.wav",
	"physics/body/body_medium_impact_hard3.wav",
	"physics/body/body_medium_impact_hard5.wav",
	"physics/body/body_medium_impact_hard6.wav",
	"physics/body/body_medium_impact_soft5.wav",
	"physics/body/body_medium_impact_soft6.wav",
	"physics/body/body_medium_impact_soft7.wav",
}

--[[
function ULib.applyAccel( ent, magnitude, direction, dTime )
	if dTime == nil then dTime = 1 end

	if magnitude ~= nil then
		direction:Normalize()
	else
		magnitude = 1
	end

	-- Times it by the time elapsed since the last update.
	local accel = magnitude * dTime
	-- Convert our scalar accel to a vector accel
	accel = direction * accel

	if ent:GetMoveType() == MOVETYPE_VPHYSICS then
		-- a = f/m , so times by mass to get the force.
		local force = accel * ent:GetPhysicsObject():GetMass()
		ent:GetPhysicsObject():ApplyForceCenter( force )
	else
		ent:SetVelocity( accel ) -- As it turns out, SetVelocity() is actually SetAccel() in GM10
	end
end --]]

function PYRITION:PlayerSlap(ply, noise, damage, force)
	if ply:GetMoveType() == MOVETYPE_OBSERVER then return false, "player.slap.fail.spectator" end
	
	if ply:Alive() then
		if ply:InVehicle() then ply:ExitVehicle() end
		if ply:GetMoveType() == MOVETYPE_NOCLIP then ply:SetMoveType(MOVETYPE_WALK) end
		
		do --view punch
			local pitch = math.Rand(-20, 20)
			local yaw = math.sqrt(400 - pitch ^ 2)
			
			--flip 50% of the time
			if math.random() < 0.5 then yaw = -yaw end
			
			ply:ViewPunch(Angle(pitch, yaw, 0))
		end
		
		if damage then
			local health = ply:Health()
			
			if health > damage then ply:SetHealth(health - damage)
			else ply:Kill() end
		end
		
		if noise then ply:EmitSound(slap_sounds[math.random(#slap_sounds)]) end
		
		if force then
			--local direction = Vector( math.random( 20 )-10, math.random( 20 )-10, math.random( 20 )-5 ) -- Make it random, slightly biased to go up.
			--ULib.applyAccel( ent, power, direction )
		end
	else
		local ragdoll = ply:GetRagdollEntity()
		
		if IsValid(ragdoll) then
			
		end
		
		return false, "player.slap.fail"
	end
end