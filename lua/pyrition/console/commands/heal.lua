PYRITION:ConsoleCommandRegister("heal", {
	Arguments = {"Player Default"},
	Console = true,

	Execute = function(ply, targets)
		local healed_targets = {}

		for index, target in ipairs(targets) do
			local healed = false

			if not target:Alive() then --revive
				healed = true

				target:Spawn()
			elseif target:Health() < maximum_health then --heal
				healed = true

				target:SetHealth(target:GetMaxHealth())
			end

			if target:IsOnFire() then --extinguish
				healed = true

				target:Extinguish()
			end

			if healed then table.insert(healed_targets, target) end
		end

		if healed[1] then return true, {targets = healed_targets}
		else return false, nil, PYRITION_COMMAND_MISSED end
	end
})